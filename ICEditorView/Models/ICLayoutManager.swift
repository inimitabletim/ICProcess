//
//  ICLayoutManager.swift
//  ICPinAssignmentViewer
//
//  Created by TimChi on 2025/3/26.
//

import Foundation
import SwiftUI
import Combine

// 匯入結果結構體
struct ImportResult {
    let success: Bool
    let message: String
}


class ICLayoutManager: ObservableObject {
    // 基本元件集合
    @Published var integratedCircuits: [UUID: ModelIntegratedCircuit] = [:]
    @Published var pins: [UUID: ModelPin] = [:]
    @Published var pads: [UUID: ModelPAD] = [:]
    @Published var pgPins: [UUID: ModelICPGPin] = [:]
    @Published var ioPins: [UUID: ModelICIOPin] = [:]
    @Published var ioPinSetups: [UUID: ModelICIOPinSetup] = [:]
    @Published var innerPads: [UUID: ModelICInnerPAD] = [:]
    @Published var padDimensions: [UUID: ModelPADDimension] = [:]
    @Published var pgCells: [UUID: ModelICPGCell] = [:]
    @Published var ioCells: [UUID: ModelICIOCell] = [:]
    
    // 選擇狀態
    @Published var selectedComponents: Set<UUID> = []
    
    // 撤銷/重做歷史記錄
    private struct HistoryState {
        var integratedCircuits: [UUID: ModelIntegratedCircuit]
        var pins: [UUID: ModelPin]
        var pads: [UUID: ModelPAD]
        var pgPins: [UUID: ModelICPGPin]
        var ioPins: [UUID: ModelICIOPin]
        var ioPinSetups: [UUID: ModelICIOPinSetup]
        var innerPads: [UUID: ModelICInnerPAD]
        var padDimensions: [UUID: ModelPADDimension]
        var pgCells: [UUID: ModelICPGCell]
        var ioCells: [UUID: ModelICIOCell]
    }
    
    private var history: [HistoryState] = []
    private var currentHistoryIndex = -1
    private let maxHistoryCount = 50
    
    init() {
        // 初始化操作
    }
    
    // MARK: - 記錄歷史
    
    func recordHistory() {
        // 如果當前不是最新歷史，清除之後的歷史
        if currentHistoryIndex < history.count - 1 {
            history.removeSubrange((currentHistoryIndex + 1)...)
        }
        
        // 創建當前狀態的歷史記錄
        let currentState = HistoryState(
            integratedCircuits: integratedCircuits,
            pins: pins,
            pads: pads,
            pgPins: pgPins,
            ioPins: ioPins,
            ioPinSetups: ioPinSetups,
            innerPads: innerPads,
            padDimensions: padDimensions,
            pgCells: pgCells,
            ioCells: ioCells
        )
        
        history.append(currentState)
        currentHistoryIndex = history.count - 1
        
        // 限制歷史記錄數量
        if history.count > maxHistoryCount {
            history.removeFirst()
            currentHistoryIndex -= 1
        }
    }
    
    // MARK: - 撤銷與重做
    
    func undo() {
        guard currentHistoryIndex > 0 else { return }
        
        currentHistoryIndex -= 1
        restoreState(from: history[currentHistoryIndex])
    }
    
    func redo() {
        guard currentHistoryIndex < history.count - 1 else { return }
        
        currentHistoryIndex += 1
        restoreState(from: history[currentHistoryIndex])
    }
    
    private func restoreState(from state: HistoryState) {
        // 恢復所有狀態
        integratedCircuits = state.integratedCircuits
        pins = state.pins
        pads = state.pads
        pgPins = state.pgPins
        ioPins = state.ioPins
        ioPinSetups = state.ioPinSetups
        innerPads = state.innerPads
        padDimensions = state.padDimensions
        pgCells = state.pgCells
        ioCells = state.ioCells
    }
    
    // MARK: - 元件操作方法
    
    // Pin 操作
    func addPin(_ pin: ModelPin) {
        recordHistory()
        pins[pin.id] = pin
    }
    
    func updatePin(_ pin: ModelPin) {
        recordHistory()
        pins[pin.id] = pin
    }
    
    func removePin(id: UUID) {
        recordHistory()
        pins.removeValue(forKey: id)
    }
    
    // PAD 操作
    func addPAD(_ pad: ModelPAD) {
        recordHistory()
        pads[pad.id] = pad
    }
    
    func updatePAD(_ pad: ModelPAD) {
        recordHistory()
        pads[pad.id] = pad
        objectWillChange.send()  // 確保這一行存在
    }
    
    /// 更新PAD旋轉角度
    /// - Parameters:
    ///   - padID: PAD的唯一識別碼
    ///   - angle: 新的旋轉角度（以度為單位，0-360範圍）
    func updatePADRotation(padID: UUID, angle: Double) {
        // 確保PAD存在
        guard var pad = pads[padID] else {
            print("⚠️ 無法更新旋轉：找不到PAD (ID: \(padID))")
            return
        }
        
        // 記錄操作歷史
        recordHistory()
        
        // 更新旋轉角度
        pad.rotatedAngle = angle
        
        // 更新PAD
        pads[padID] = pad
        
        // 通知觀察者
        objectWillChange.send()
    }
    
    func removePAD(id: UUID) {
        recordHistory()
        pads.removeValue(forKey: id)
    }
    
    // 其他元件類型的增刪改方法...（省略類似方法）
    
    // MARK: - 選擇操作
    
    func selectComponent(id: UUID) {
        selectedComponents.insert(id)
    }
    
    func deselectComponent(id: UUID) {
        selectedComponents.remove(id)
    }
    
    func toggleSelection(id: UUID) {
        if selectedComponents.contains(id) {
            selectedComponents.remove(id)
        } else {
            selectedComponents.insert(id)
        }
    }
    
    func clearSelection() {
        selectedComponents.removeAll()
    }
    
    // MARK: - 關聯操作
    
    // 連結Pin到PAD
    func linkPinToPAD(pinID: UUID, padID: UUID) {
        guard var pin = pins[pinID], pads[padID] != nil else { return }
        
        recordHistory()
        if !pin.padIDs.contains(padID) {
            pin.padIDs.append(padID)
            pins[pinID] = pin
        }
        
        // 同時更新PAD的關聯
        if var pad = pads[padID] {
            if !pad.pinIDs.contains(pinID) {
                pad.pinIDs.append(pinID)
                pads[padID] = pad
            }
        }
    }
    
    // MARK: - 關聯管理增強方法
    
    /// 建立Pin和PAD之間的關聯，並確保雙向一致性
    /// - Parameters:
    ///   - pinID: Pin的唯一識別碼
    ///   - padID: PAD的唯一識別碼
    ///   - recordToHistory: 是否記錄到歷史紀錄(預設為true)
    /// - Returns: 是否成功建立關聯
    @discardableResult
    func associatePinToPAD(pinID: UUID, padID: UUID, recordToHistory: Bool = true) -> Bool {
        // 確保Pin和PAD都存在
        guard var pin = pins[pinID], var pad = pads[padID] else {
            print("⚠️ 關聯失敗: Pin或PAD不存在 (pinID: \(pinID), padID: \(padID))")
            return false
        }
        
        // 檢查是否已經建立關聯
        let pinAlreadyHasPad = pin.padIDs.contains(padID)
        let padAlreadyHasPin = pad.pinIDs.contains(pinID)
        
        // 如果雙向都已建立，無需任何操作
        if pinAlreadyHasPad && padAlreadyHasPin {
            print("📝 關聯已存在，無需更新 (pinID: \(pinID), padID: \(padID))")
            return true
        }
        
        // 如果需要記錄歷史，在修改前保存
        if recordToHistory {
            recordHistory()
        }
        
        // 更新Pin的PAD列表
        if !pinAlreadyHasPad {
            pin.padIDs.append(padID)
            pins[pinID] = pin
        }
        
        // 更新PAD的Pin列表
        if !padAlreadyHasPin {
            pad.pinIDs.append(pinID)
            pads[padID] = pad
        }
        
        // 發送更新通知
        objectWillChange.send()
        
        print("✅ 成功建立關聯 (pinID: \(pinID), padID: \(padID))")
        return true
    }
    
    /// 解除Pin和PAD之間的關聯
    /// - Parameters:
    ///   - pinID: Pin的唯一識別碼
    ///   - padID: PAD的唯一識別碼
    ///   - recordToHistory: 是否記錄到歷史紀錄(預設為true)
    /// - Returns: 是否成功解除關聯
    @discardableResult
    func dissociatePinFromPAD(pinID: UUID, padID: UUID, recordToHistory: Bool = true) -> Bool {
        // 檢查Pin和PAD是否存在
        guard var pin = pins[pinID], var pad = pads[padID] else {
            print("⚠️ 解除關聯失敗: Pin或PAD不存在 (pinID: \(pinID), padID: \(padID))")
            return false
        }
        
        // 檢查是否有關聯存在
        let pinHasPad = pin.padIDs.contains(padID)
        let padHasPin = pad.pinIDs.contains(pinID)
        
        // 如果沒有任何關聯，無需操作
        if !pinHasPad && !padHasPin {
            print("📝 無關聯存在，無需解除 (pinID: \(pinID), padID: \(padID))")
            return true
        }
        
        // 如果需要記錄歷史，在修改前保存
        if recordToHistory {
            recordHistory()
        }
        
        // 更新Pin的PAD列表
        if pinHasPad {
            pin.padIDs.removeAll { $0 == padID }
            pins[pinID] = pin
        }
        
        // 更新PAD的Pin列表
        if padHasPin {
            pad.pinIDs.removeAll { $0 == pinID }
            pads[padID] = pad
        }
        
        // 發送更新通知
        objectWillChange.send()
        
        print("✅ 成功解除關聯 (pinID: \(pinID), padID: \(padID))")
        return true
    }
    
    /// 批量建立關聯 - 將多個Pin關聯到同一個PAD
    /// - Parameters:
    ///   - pinIDs: Pin的唯一識別碼集合
    ///   - padID: PAD的唯一識別碼
    /// - Returns: 成功建立關聯的數量
    @discardableResult
    func batchAssociatePinsToPAD(pinIDs: [UUID], padID: UUID) -> Int {
        // 確保PAD存在
        guard pads[padID] != nil else {
            print("⚠️ 批量關聯失敗: PAD不存在 (padID: \(padID))")
            return 0
        }
        
        // 記錄一次歷史，避免多次記錄
        recordHistory()
        
        // 計算成功數量
        var successCount = 0
        
        // 逐一建立關聯
        for pinID in pinIDs {
            if associatePinToPAD(pinID: pinID, padID: padID, recordToHistory: false) {
                successCount += 1
            }
        }
        
        return successCount
    }
    
    /// 批量建立關聯 - 將一個Pin關聯到多個PAD
    /// - Parameters:
    ///   - pinID: Pin的唯一識別碼
    ///   - padIDs: PAD的唯一識別碼集合
    /// - Returns: 成功建立關聯的數量
    @discardableResult
    func batchAssociatePinToPADs(pinID: UUID, padIDs: [UUID]) -> Int {
        // 確保Pin存在
        guard pins[pinID] != nil else {
            print("⚠️ 批量關聯失敗: Pin不存在 (pinID: \(pinID))")
            return 0
        }
        
        // 記錄一次歷史，避免多次記錄
        recordHistory()
        
        // 計算成功數量
        var successCount = 0
        
        // 逐一建立關聯
        for padID in padIDs {
            if associatePinToPAD(pinID: pinID, padID: padID, recordToHistory: false) {
                successCount += 1
            }
        }
        
        return successCount
    }
    
    /// 清除Pin的所有PAD關聯
    /// - Parameter pinID: Pin的唯一識別碼
    /// - Returns: 被清除的關聯數量
    @discardableResult
    func clearPinAssociations(pinID: UUID) -> Int {
        guard let pin = pins[pinID] else {
            return 0
        }
        
        let associationCount = pin.padIDs.count
        if associationCount == 0 {
            return 0
        }
        
        // 記錄歷史
        recordHistory()
        
        // 創建關聯PAD的ID副本
        let padIDsCopy = pin.padIDs
        
        // 逐一解除關聯
        for padID in padIDsCopy {
            dissociatePinFromPAD(pinID: pinID, padID: padID, recordToHistory: false)
        }
        
        return associationCount
    }
    
    /// 清除PAD的所有Pin關聯
    /// - Parameter padID: PAD的唯一識別碼
    /// - Returns: 被清除的關聯數量
    @discardableResult
    func clearPADAssociations(padID: UUID) -> Int {
        guard let pad = pads[padID] else {
            return 0
        }
        
        let associationCount = pad.pinIDs.count
        if associationCount == 0 {
            return 0
        }
        
        // 記錄歷史
        recordHistory()
        
        // 創建關聯Pin的ID副本
        let pinIDsCopy = pad.pinIDs
        
        // 逐一解除關聯
        for pinID in pinIDsCopy {
            dissociatePinFromPAD(pinID: pinID, padID: padID, recordToHistory: false)
        }
        
        return associationCount
    }
    
    /// 獲取特定Pin關聯的所有PAD
    /// - Parameter pinID: Pin的唯一識別碼
    /// - Returns: 關聯的PAD字典，若Pin不存在則返回空字典
    func getPADsForPin(pinID: UUID) -> [UUID: ModelPAD] {
        guard let pin = pins[pinID] else {
            return [:]
        }
        
        var result: [UUID: ModelPAD] = [:]
        for padID in pin.padIDs {
            if let pad = pads[padID] {
                result[padID] = pad
            }
        }
        
        return result
    }
    
    /// 獲取特定PAD關聯的所有Pin
    /// - Parameter padID: PAD的唯一識別碼
    /// - Returns: 關聯的Pin字典，若PAD不存在則返回空字典
    func getPinsForPAD(padID: UUID) -> [UUID: ModelPin] {
        guard let pad = pads[padID] else {
            return [:]
        }
        
        var result: [UUID: ModelPin] = [:]
        for pinID in pad.pinIDs {
            if let pin = pins[pinID] {
                result[pinID] = pin
            }
        }
        
        return result
    }
}



