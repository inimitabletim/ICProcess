//
//  TestDataGenerator.swift
//  ICPinAssignmentViewer
//
//  Created by TimChi on 2025/3/26.
//

import Foundation
import SwiftUI

/// 測試資料生成器 - 用於開發和測試
class TestDataGenerator {
    /// 生成CSV測試資料
    /// - Parameters:
    ///   - fileName: 檔案名稱
    ///   - count: 元件數量
    /// - Returns: 檔案URL
    static func generateCSVTestData(fileName: String = "test_data.csv", count: Int = 100) -> URL? {
        // 建立CSV內容
        var csvContent = "ICPinIndex,ICPADName,ICPADCenterX,ICPADCenterY,Width,Height,RotatedAngle,isInnerConnectPad,isStagger,staggerIndex\n"
        
        // 生成測試資料行
        let center = CGPoint(x: 500, y: 500)
        let maxRadius: Double = 400
        
        for i in 0..<count {
            // 計算螺旋位置 - 使元件均勻分布
            let angle = Double(i) * 0.5
            let radius = maxRadius * Double(i) / Double(count)
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            
            // 隨機生成其他屬性
            let width = Int.random(in: 30...60)
            let height = Int.random(in: 30...60)
            let rotationAngle = Double.random(in: 0...90)
            let isInnerConnectPad = Bool.random()
            let isStagger = Bool.random()
            let staggerIndex = Int.random(in: 0...5)
            
            // 建立CSV行
            let row = "\(i),PAD-\(i),\(Int(x)),\(Int(y)),\(width),\(height),\(rotationAngle),\(isInnerConnectPad),\(isStagger),\(staggerIndex)"
            csvContent.append(row + "\n")
        }
        
        // 寫入檔案
        do {
            // 獲取文檔目錄
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentDirectory.appendingPathComponent(fileName)
            
            // 寫入檔案
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            
            return fileURL
        } catch {
            print("❌ 寫入測試檔案失敗: \(error)")
            return nil
        }
    }
    
    /// 生成圓形排列的測試資料
    /// - Returns: 元件集合
    static func generateCircularLayoutComponents() -> (pins: [UUID: ModelPin], pads: [UUID: ModelPAD], dimensions: [UUID: ModelPADDimension]) {
        var pins: [UUID: ModelPin] = [:]
        var pads: [UUID: ModelPAD] = [:]
        var dimensions: [UUID: ModelPADDimension] = [:]
        
        // 設定參數
        let center = Point(x: 500, y: 500)
        let count = 32
        let radius: Double = 350
        
        for i in 0..<count {
            // 計算角度和位置
            let angle = Double(i) * (2 * .pi / Double(count))
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            
            // 建立PAD尺寸
            let padDimensionID = UUID()
            let padDimension = ModelPADDimension(
                id: padDimensionID,
                name: "Dim-\(i)",
                height: Int32.random(in: 30...50),
                width: Int32.random(in: 40...70)
            )
            
            // 建立Pin
            let pinID = UUID()
            let pin = ModelPin(
                id: pinID,
                name: "Pin-\(i)",
                memo: "測試Pin \(i)",
                pinIndex: Int32(i),
                pinName: "Pin-\(i)",
                pinType: Int16(i % 3)
            )
            
            // 建立PAD
            let padID = UUID()
            var pad = ModelPAD(
                id: padID,
                name: "PAD-\(i)",
                memo: "測試PAD \(i)",
                centerLocateX: Int32(x),
                centerLocateY: Int32(y),
                padPinName: "PAD-\(i)",
                isInnerConnectPad: i % 5 == 0,
                isStagger: i % 7 == 0,
                rotatedAngle: angle * (180.0 / .pi),  // 角度轉換為度
                staggerIndex: Int16(i % 3)
            )
            
            // 建立關聯
            pad.pinIDs = [pinID]
            pad.padDimensionID = padDimensionID
            
            var updatedPin = pin
            updatedPin.padIDs = [padID]
            
            // 儲存元件
            pins[pinID] = updatedPin
            pads[padID] = pad
            dimensions[padDimensionID] = padDimension
        }
        
        return (pins, pads, dimensions)
    }
    
    /// 將測試資料加載到ICLayoutManager
    /// - Parameter manager: 目標ICLayoutManager
    static func loadTestDataToManager(_ manager: ICLayoutManager) {
        // 生成測試資料
        let components = generateCircularLayoutComponents()
        
        // 更新管理器
        manager.pins = components.pins
        manager.pads = components.pads
        manager.padDimensions = components.dimensions
        
        // 記錄更改
        manager.recordHistory()
    }
}

/// ICLayoutManager擴展 - 測試資料功能
extension ICLayoutManager {
    /// 載入測試資料
    func loadTestData() {
        TestDataGenerator.loadTestDataToManager(self)
    }
    
    /// 從檔案目錄載入特定測試檔案
    /// - Parameter fileName: 檔案名稱
    /// - Returns: 操作結果
    func loadTestFile(fileName: String) -> (success: Bool, message: String) {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentDirectory.appendingPathComponent(fileName)
        
        // 檢查檔案是否存在
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return (false, "找不到檔案: \(fileName)")
        }
        
        // 嘗試匯入
        return importFromCSV(url: fileURL)
    }
}
