//
//  ICLayoutViewModel.swift
//  ICEditorView
//
//  Created by TimChi on 2025/3/27.
//

import SwiftUI
import Combine

// 基礎視圖模型 - 包含所有共用功能
class ICLayoutViewModel: ObservableObject {
    // 數據模型
    @Published var pins: [ModelPin] = []
    @Published var pads: [ModelPAD] = []
    @Published var padDimensions: [UUID: ModelPADDimension] = [:]
    
    // 選擇狀態
    @Published var selectedPinIDs: Set<UUID> = []
    @Published var selectedPADIDs: Set<UUID> = []
    
    // MARK: - 初始化和數據加載
    
    init() {
        // 可以添加基本初始化邏輯
    }
    
    // 從CSV加載數據
    func loadFromCSV(url: URL) -> (success: Bool, message: String) {
        // 使用 CSVParser 解析數據
        let parser = CSVParser()
        let result = parser.parseCSV(from: url)
        
        switch result {
        case .success(let parseResult):
            // 更新模型數據
            self.pins = []  // 清除現有數據
            self.pads = []
            self.padDimensions = [:]
            
            // 轉換數據格式 (從字典到數組)
            self.pins = Array(parseResult.pins.values)
            self.pads = Array(parseResult.pads.values)
            self.padDimensions = parseResult.padDimensions
            
            // 清除選擇狀態
            self.clearSelection()
            
            // 通知視圖更新
            self.objectWillChange.send()
            
            return (true, "成功匯入CSV資料 - \(parseResult.pins.count) 個Pin和 \(parseResult.pads.count) 個PAD")
            
        case .failure(let error):
            return (false, "CSV匯入失敗: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 選擇與操作邏輯
    
    func selectPin(id: UUID) {
        if selectedPinIDs.contains(id) {
            selectedPinIDs.remove(id)
        } else {
            selectedPinIDs.insert(id)
        }
    }
    
    func selectPAD(id: UUID) {
        if selectedPADIDs.contains(id) {
            selectedPADIDs.remove(id)
        } else {
            selectedPADIDs.insert(id)
        }
    }
    
    func clearSelection() {
        selectedPinIDs.removeAll()
        selectedPADIDs.removeAll()
    }
    
    // MARK: - 元件查詢和操作
    
    // 獲取Pin的位置
    func getPositionForPin(_ pin: ModelPin) -> CGPoint? {
        if let padID = pin.padIDs.first, let pad = pads.first(where: { $0.id == padID }) {
            return CGPoint(x: CGFloat(pad.centerLocateX), y: CGFloat(pad.centerLocateY))
        }
        return nil
    }
    
    // 獲取PAD關聯的Pin
    func pinsForPAD(padID: UUID) -> [ModelPin] {
        return pins.filter { pin in
            pin.padIDs.contains(padID)
        }
    }
    
    // 獲取Pin關聯的PAD
    func padsForPin(pinID: UUID) -> [ModelPAD] {
        if let pin = pins.first(where: { $0.id == pinID }) {
            return pin.padIDs.compactMap { padID in
                pads.first { $0.id == padID }
            }
        }
        return []
    }
    
    // MARK: - 數據修改操作
    
    // 更新PAD位置
    func updatePADPosition(padID: UUID, x: Double, y: Double) {
        if let index = pads.firstIndex(where: { $0.id == padID }) {
            pads[index].centerLocateX = Int32(x)
            pads[index].centerLocateY = Int32(y)
        }
    }
    
    // 添加Pin和PAD關聯
    func associatePinToPAD(pinID: UUID, padID: UUID) {
        if let pinIndex = pins.firstIndex(where: { $0.id == pinID }) {
            if !pins[pinIndex].padIDs.contains(padID) {
                pins[pinIndex].padIDs.append(padID)
            }
        }
    }
    
    // 移除Pin和PAD關聯
    func dissociatePinFromPAD(pinID: UUID, padID: UUID) {
        if let pinIndex = pins.firstIndex(where: { $0.id == pinID }) {
            pins[pinIndex].padIDs.removeAll { $0 == padID }
        }
    }
}

// 開發者特定視圖模型 - 繼承基礎視圖模型並添加開發者功能
class DeveloperICLayoutViewModel: ICLayoutViewModel {
    // 開發模式特定屬性
    @Published var showPerformanceMetrics: Bool = false
    @Published var debugInfoVisible: Bool = false
    @Published var testMode: Bool = false
    
    // 開發模式特定方法
    func generateTestData(pinCount: Int = 10, padCount: Int = 20) {
        // 清空現有數據
        pins.removeAll()
        pads.removeAll()
        padDimensions.removeAll()
        
        // 創建測試尺寸
        let testDimension = ModelPADDimension(
            name: "TestDimension",
            height: 40,
            width: 60
        )
        padDimensions[testDimension.id] = testDimension
        
        // 創建測試PAD
        for i in 0..<padCount {
            let posX = Int32(200 + 100 * cos(Double(i) * 2 * .pi / Double(padCount)))
            let posY = Int32(200 + 100 * sin(Double(i) * 2 * .pi / Double(padCount)))
            
            var pad = ModelPAD(
                name: "PAD\(i+1)",
                centerLocateX: posX,
                centerLocateY: posY,
                padPinName: "P\(i+1)",
                isInnerConnectPad: false,
                isStagger: false,
                rotatedAngle: Double(i) * 360 / Double(padCount)
            )
            pad.padDimensionID = testDimension.id
            pads.append(pad)
        }
        
        // 創建測試Pin
        for i in 0..<pinCount {
            var pin = ModelPin(
                name: "PIN\(i+1)",
                pinIndex: Int32(i),
                pinName: "P\(i+1)"
            )
            
            // 將Pin關聯到PAD (一個Pin可以關聯到多個PAD)
            let padIndex1 = i % padCount
            let padIndex2 = (i + padCount/2) % padCount
            pin.padIDs.append(pads[padIndex1].id)
            pin.padIDs.append(pads[padIndex2].id)
            
            pins.append(pin)
        }
    }
    
    func exportDebugInformation() -> String {
        // 導出調試信息
        var debugInfo = "調試信息:\n"
        debugInfo += "Pin數量: \(pins.count)\n"
        debugInfo += "PAD數量: \(pads.count)\n"
        debugInfo += "已選擇Pin: \(selectedPinIDs.count)\n"
        debugInfo += "已選擇PAD: \(selectedPADIDs.count)\n"
        
        // 添加選擇的Pin詳情
        if !selectedPinIDs.isEmpty {
            debugInfo += "\n選擇的Pin:\n"
            for pinID in selectedPinIDs {
                if let pin = pins.first(where: { $0.id == pinID }) {
                    debugInfo += "- \(pin.name) (\(pin.pinName)): 關聯PAD數量: \(pin.padIDs.count)\n"
                }
            }
        }
        
        return debugInfo
    }
}

// 添加到 ICLayoutViewModel.swift 中

extension ICLayoutViewModel {
    /// 數據一致性檢查結果結構
    struct ValidationResult {
        var removedPinToPadReferences: Int = 0        // 移除的Pin到PAD無效引用數量
        var removedPadToPinReferences: Int = 0        // 移除的PAD到Pin無效引用數量
        var repairedPinToPadReferences: Int = 0       // 修復的Pin到PAD單向引用數量
        var repairedPadToPinReferences: Int = 0       // 修復的PAD到Pin單向引用數量
        var removedPadDimensionReferences: Int = 0    // 移除的無效PADDimension引用數量
        
        var totalIssues: Int {
            return removedPinToPadReferences +
                   removedPadToPinReferences +
                   repairedPinToPadReferences +
                   repairedPadToPinReferences +
                   removedPadDimensionReferences
        }
        
        var description: String {
            """
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
        
        // 1. 建立快速查詢用的ID集合
        let validPinIDs = Set(pins.map { $0.id })
        let validPadIDs = Set(pads.map { $0.id })
        let validDimensionIDs = Set(padDimensions.keys)
        
        // 建立PAD ID到索引的映射，提高查詢效率
        var padIDToIndex: [UUID: Int] = [:]
        for (index, pad) in pads.enumerated() {
            padIDToIndex[pad.id] = index
        }
        
        // 建立Pin ID到索引的映射
        var pinIDToIndex: [UUID: Int] = [:]
        for (index, pin) in pins.enumerated() {
            pinIDToIndex[pin.id] = index
        }
        
        // 2. 檢查並修復Pin到PAD的引用
        for (pinIndex, pin) in pins.enumerated() {
            // 檢查每個Pin的PAD引用是否有效
            let validPadRefs = pin.padIDs.filter { validPadIDs.contains($0) }
            let invalidCount = pin.padIDs.count - validPadRefs.count
            
            if invalidCount > 0 {
                // 移除無效的PAD引用
                result.removedPinToPadReferences += invalidCount
                pins[pinIndex].padIDs = validPadRefs
            }
            
            // 檢查雙向引用一致性
            for padID in validPadRefs {
                if let padIndex = padIDToIndex[padID] {
                    let pad = pads[padIndex]
                    
                    // 如果PAD沒有引用回這個Pin，修復它
                    if !pad.pinIDs.contains(pin.id) {
                        result.repairedPadToPinReferences += 1
                        var updatedPad = pad
                        updatedPad.pinIDs.append(pin.id)
                        pads[padIndex] = updatedPad
                    }
                }
            }
        }
        
        // 3. 檢查並修復PAD到Pin的引用
        for (padIndex, pad) in pads.enumerated() {
            // 檢查每個PAD的Pin引用是否有效
            let validPinRefs = pad.pinIDs.filter { validPinIDs.contains($0) }
            let invalidCount = pad.pinIDs.count - validPinRefs.count
            
            if invalidCount > 0 {
                // 移除無效的Pin引用
                result.removedPadToPinReferences += invalidCount
                pads[padIndex].pinIDs = validPinRefs
            }
            
            // 檢查雙向引用一致性
            for pinID in validPinRefs {
                if let pinIndex = pinIDToIndex[pinID] {
                    let pin = pins[pinIndex]
                    
                    // 如果Pin沒有引用回這個PAD，修復它
                    if !pin.padIDs.contains(pad.id) {
                        result.repairedPinToPadReferences += 1
                        var updatedPin = pin
                        updatedPin.padIDs.append(pad.id)
                        pins[pinIndex] = updatedPin
                    }
                }
            }
            
            // 4. 檢查PAD的Dimension引用
            if let dimensionID = pad.padDimensionID, !validDimensionIDs.contains(dimensionID) {
                // 如果引用了不存在的Dimension，移除引用
                result.removedPadDimensionReferences += 1
                pads[padIndex].padDimensionID = nil
            }
        }
        
        // 如果有修改，通知觀察者
        if result.totalIssues > 0 {
            objectWillChange.send()
        }
        
        return result
    }
    
    /// 在CSV導入後調用數據驗證
    func loadFromCSVWithValidation(url: URL) -> (success: Bool, message: String) {
        let importResult = loadFromCSV(url: url)
        
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
