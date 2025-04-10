//
//  CSVParser.swift
//  ICPinAssignmentViewer
//
//  Created by TimChi on 2025/3/26.
//

import Foundation
import SwiftUI

/// CSV解析錯誤類型
enum CSVParseError: Error, LocalizedError {
    case fileNotFound
    case invalidFormat
    case missingRequiredColumns
    case invalidDataType(row: Int, column: String)
    case emptyFile
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "找不到CSV檔案"
        case .invalidFormat:
            return "CSV格式無效"
        case .missingRequiredColumns:
            return "CSV缺少必要欄位"
        case .invalidDataType(let row, let column):
            return "第\(row)行的\(column)欄位資料類型無效"
        case .emptyFile:
            return "CSV檔案為空"
        }
    }
}

/// CSV解析結果結構
struct CSVParseResult {
    var pins: [UUID: ModelPin]
    var pads: [UUID: ModelPAD]
    var padDimensions: [UUID: ModelPADDimension]
}

/// CSV解析器類別
class CSVParser {
    // 必要的CSV列名
    private let requiredColumns = [
        "ICPinIndex", "ICPADName", "ICPADCenterX", "ICPADCenterY",
        "Width", "Height", "RotatedAngle", "isInnerConnectPad",
        "isStagger", "staggerIndex"
    ]
    
    /// 解析CSV檔案
    /// - Parameter url: CSV檔案URL
    /// - Returns: 解析結果或錯誤
    func parseCSV(from url: URL) -> Result<CSVParseResult, CSVParseError> {
        do {
            // 讀取檔案內容
            let content = try String(contentsOf: url, encoding: .utf8)
            
            // 分割行
            var rows = content.components(separatedBy: .newlines)
            
            // 檢查是否為空檔案
            guard !rows.isEmpty else {
                return .failure(.emptyFile)
            }
            
            // 移除空行
            rows = rows.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            
            // 取得標題行
            guard let headerRow = rows.first else {
                return .failure(.invalidFormat)
            }
            
            // 解析標題
            let headers = headerRow.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            
            // 檢查必要欄位是否存在
            for column in requiredColumns {
                guard headers.contains(column) else {
                    return .failure(.missingRequiredColumns)
                }
            }
            
            // 初始化集合
            var pins: [UUID: ModelPin] = [:]
            var pads: [UUID: ModelPAD] = [:]
            var padDimensions: [UUID: ModelPADDimension] = [:]
            var pinIndexToIDMap: [Int32: UUID] = [:] // 用於建立關聯
            
            // 解析資料行
            for (rowIndex, row) in rows.enumerated() {
                // 跳過標題行
                guard rowIndex > 0 else { continue }
                
                // 分割欄位
                let columns = row.components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                
                // 確保欄位數量正確
                guard columns.count >= requiredColumns.count else { continue }
                
                // 建立欄位對應字典
                var columnDict: [String: String] = [:]
                for (index, header) in headers.enumerated() {
                    if index < columns.count {
                        columnDict[header] = columns[index]
                    }
                }
                
                // 解析欄位

                // 解析ICPinIndex
                guard let pinIndexStr = columnDict["ICPinIndex"],
                      let pinIndex = Int32(pinIndexStr) else {
                    return .failure(.invalidDataType(row: rowIndex, column: "ICPinIndex"))
                }
                
                // 解析PAD相關欄位
                guard let padName = columnDict["ICPADName"],
                      let centerXStr = columnDict["ICPADCenterX"],
                      let centerYStr = columnDict["ICPADCenterY"],
                      let widthStr = columnDict["Width"],
                      let heightStr = columnDict["Height"],
                      let rotatedAngleStr = columnDict["RotatedAngle"],
                      let isInnerConnectPadStr = columnDict["isInnerConnectPad"],
                      let isStaggerStr = columnDict["isStagger"],
                      let staggerIndexStr = columnDict["staggerIndex"],
                      let centerX = Int32(centerXStr),
                      let centerY = Int32(centerYStr),
                      let width = Int32(widthStr),
                      let height = Int32(heightStr),
                      let rotatedAngle = Double(rotatedAngleStr),
                      let staggerIndex = Int16(staggerIndexStr) else {
                    return .failure(.invalidDataType(row: rowIndex, column: "PAD資料"))
                }
                
                // 轉換布爾值
                let isInnerConnectPad = isInnerConnectPadStr.lowercased() == "true"
                let isStagger = isStaggerStr.lowercased() == "true"
                
                // 建立Pin
                let pinID = UUID()
                let pin = ModelPin(
                    id: pinID,
                    name: "Pin-\(pinIndex)",
                    pinIndex: pinIndex,
                    pinName: "Pin-\(pinIndex)",
                    pinType: 0
                )
                pins[pinID] = pin
                pinIndexToIDMap[pinIndex] = pinID
                
                // 建立PADDimension (如果需要)
                let padDimensionID = UUID()
                let padDimension = ModelPADDimension(
                    id: padDimensionID,
                    name: "Dim-\(padName)",
                    height: height,
                    width: width
                )
                padDimensions[padDimensionID] = padDimension
                
                // 建立PAD
                let padID = UUID()
                var pad = ModelPAD(
                    id: padID,
                    name: padName,
                    centerLocateX: centerX,
                    centerLocateY: centerY,
                    padPinName: padName,
                    isInnerConnectPad: isInnerConnectPad,
                    isStagger: isStagger,
                    rotatedAngle: rotatedAngle,
                    staggerIndex: staggerIndex
                )
                
                // 建立關聯
                pad.pinIDs = [pinID]
                pad.padDimensionID = padDimensionID
                pads[padID] = pad
                
                // 更新Pin的PAD關聯
                var updatedPin = pin
                updatedPin.padIDs = [padID]
                pins[pinID] = updatedPin
                
                // 更新PADDimension的PAD關聯
                var updatedDimension = padDimension
                updatedDimension.padIDs = [padID]
                padDimensions[padDimensionID] = updatedDimension
            }
            
            return .success(CSVParseResult(pins: pins, pads: pads, padDimensions: padDimensions))
            
        } catch {
            return .failure(.fileNotFound)
        }
    }
}

/// CSV解析擴展 - 用於ICLayoutManager
extension ICLayoutManager {
    /// 從CSV匯入資料
    /// - Parameter url: CSV檔案URL
    /// - Returns: 是否成功及錯誤訊息
    func importFromCSV(url: URL) -> (success: Bool, message: String) {
        let parser = CSVParser()
        let result = parser.parseCSV(from: url)
        
        switch result {
        case .success(let parseResult):
            // 更新資料模型
            self.pins = parseResult.pins
            self.pads = parseResult.pads
            self.padDimensions = parseResult.padDimensions
            
            // 記錄歷史
            self.recordHistory()
            
            return (true, "成功匯入CSV資料 - 匯入 \(parseResult.pins.count) 個Pin和 \(parseResult.pads.count) 個PAD")
            
        case .failure(let error):
            return (false, "CSV匯入失敗: \(error.localizedDescription)")
        }
    }
    
    /// 數據一致性檢查結果結構
    struct ValidationResult {
        var removedPinToPadReferences: Int = 0
        var removedPadToPinReferences: Int = 0
        var repairedPinToPadReferences: Int = 0
        var repairedPadToPinReferences: Int = 0
        var removedPadDimensionReferences: Int = 0
        
        var totalIssues: Int {
            return removedPinToPadReferences +
                   removedPadToPinReferences +
                   repairedPinToPadReferences +
                   repairedPadToPinReferences +
                   removedPadDimensionReferences
        }
        
        var description: String {
            return """
            數據一致性檢查結果:
            - 移除的Pin到PAD無效引用: \(removedPinToPadReferences)
            - 移除的PAD到Pin無效引用: \(removedPadToPinReferences)
            - 修復的Pin到PAD單向引用: \(repairedPinToPadReferences)
            - 修復的PAD到Pin單向引用: \(repairedPadToPinReferences)
            - 移除的無效PADDimension引用: \(removedPadDimensionReferences)
            - 總修復問題數: \(totalIssues)
            """
        }
    }
    
    /// 執行完整的數據一致性檢查與修復
    /// - Returns: 驗證結果報告
    @discardableResult
    func validateAndCleanData() -> ValidationResult {
        var result = ValidationResult()
        
        // 1. 獲取有效ID集合
        let validPinIDs = Set(pins.keys)
        let validPadIDs = Set(pads.keys)
        let validDimensionIDs = Set(padDimensions.keys)
        
        // 2. 檢查和修復Pin到PAD的引用
        for (pinID, pin) in pins {
            var updatedPin = pin
            let originalPadIDsCount = updatedPin.padIDs.count
            
            // 移除無效PAD引用
            updatedPin.padIDs = updatedPin.padIDs.filter { validPadIDs.contains($0) }
            let removedCount = originalPadIDsCount - updatedPin.padIDs.count
            result.removedPinToPadReferences += removedCount
            
            // 檢查雙向引用一致性
            for padID in updatedPin.padIDs {
                if let pad = pads[padID] {
                    if !pad.pinIDs.contains(pinID) {
                        // PAD沒有引用回Pin，修復它
                        var updatedPad = pad
                        updatedPad.pinIDs.append(pinID)
                        pads[padID] = updatedPad
                        result.repairedPadToPinReferences += 1
                    }
                }
            }
            
            // 如果有修改，更新Pin
            if removedCount > 0 {
                pins[pinID] = updatedPin
            }
        }
        
        // 3. 檢查和修復PAD到Pin的引用
        for (padID, pad) in pads {
            var updatedPad = pad
            let originalPinIDsCount = updatedPad.pinIDs.count
            
            // 移除無效Pin引用
            updatedPad.pinIDs = updatedPad.pinIDs.filter { validPinIDs.contains($0) }
            let removedCount = originalPinIDsCount - updatedPad.pinIDs.count
            result.removedPadToPinReferences += removedCount
            
            // 檢查雙向引用一致性
            for pinID in updatedPad.pinIDs {
                if let pin = pins[pinID] {
                    if !pin.padIDs.contains(padID) {
                        // Pin沒有引用回PAD，修復它
                        var updatedPin = pin
                        updatedPin.padIDs.append(padID)
                        pins[pinID] = updatedPin
                        result.repairedPinToPadReferences += 1
                    }
                }
            }
            
            // 檢查PAD的Dimension引用
            if let dimensionID = updatedPad.padDimensionID, !validDimensionIDs.contains(dimensionID) {
                updatedPad.padDimensionID = nil
                result.removedPadDimensionReferences += 1
            }
            
            // 如果有修改，更新PAD
            if removedCount > 0 || result.removedPadDimensionReferences > 0 {
                pads[padID] = updatedPad
            }
        }
        
        // 如果有修改，記錄歷史
        if result.totalIssues > 0 {
            recordHistory()
        }
        
        return result
    }
    
    /// 從CSV匯入資料並執行數據驗證
    /// - Parameter url: CSV檔案URL
    /// - Returns: 是否成功及錯誤訊息
    func importFromCSVWithValidation(url: URL) -> (success: Bool, message: String) {
        let importResult = importFromCSV(url: url)
        
        if importResult.success {
            // 執行數據一致性檢查
            let validationResult = validateAndCleanData()
            
            // 如果有一致性問題，添加到返回信息中
            if validationResult.totalIssues > 0 {
                return (true, "\(importResult.message)\n已修復 \(validationResult.totalIssues) 個數據一致性問題")
            }
        }
        
        return importResult
    }
}

