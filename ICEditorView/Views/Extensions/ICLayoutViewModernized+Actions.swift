//
//  ICLayoutViewModernized+Actions.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/8.
//

import SwiftUI
import Combine

extension ICLayoutViewModernized {
    // MARK: - 工具欄行為
    
    // MARK: - 工具操作類型定義
    // 工具欄操作類型
    enum ToolbarAction {
        case importCSV
        case exportCSV
        case saveLayout
        case loadLayout
        case undo
        case redo
        case toggleMultiSelect
        case toggleEditMode
        case selectTool
        case panTool
        case zoomTool
        case showFileMenu
        case showEditMenu
        case showViewOptions
        case toggleSidePanel
        case showAssociationManager
    }
        
    // MARK: - 浮動工具操作
    
    // 浮動工具操作類型
    enum FloatingToolAction {
        case zoomIn
        case zoomOut
        case resetView
        case toggleGrid
        case toggleLabels
        case toggleConnections
        case showSettings
        case centerSelection
    }
        
    // MARK: - 元件操作
    
    // 處理元件點擊
    func handleComponentTap(_ componentID: UUID) {
        // 檢查多選模式
        if gestureState.gestureModifiers.contains(.shift) || isMultiSelectMode {
            toggleComponentSelection(componentID)
        } else {
            selectSingleComponent(componentID)
        }
    }
    
    func toggleComponentSelection(_ componentID: UUID) {
        if layoutManager.selectedComponents.contains(componentID) {
            layoutManager.deselectComponent(id: componentID)
        } else {
            layoutManager.selectComponent(id: componentID)
        }
        showFeedback("批量選擇: \(layoutManager.selectedComponents.count)個元件", true)
    }
    
    func selectSingleComponent(_ componentID: UUID) {
        layoutManager.clearSelection()
        layoutManager.selectComponent(id: componentID)
        
        // 顯示元件詳細資訊
        showComponentDetails(for: componentID)
        
        showFeedback("已選擇元件", true)
    }
    
    // MARK: - CSV 匯入處理
    
    func handleCSVImport(result: Result<[URL], Error>) {
        do {
            // 獲取選擇的檔案URL
            let selectedFiles = try result.get()
            
            // 確保選擇了檔案
            guard let selectedFile = selectedFiles.first else {
                showImportAlert(success: false, message: "未選擇檔案")
                return
            }
            
            // 取得檔案存取權限
            if selectedFile.startAccessingSecurityScopedResource() {
                defer { selectedFile.stopAccessingSecurityScopedResource() }
                
                // 使用增強版匯入功能處理檔案
                let importResult = viewModel.loadFromCSVWithValidation(url: selectedFile)
                
                // 如果成功，更新layoutManager中的數據
                if importResult.success {
                    handleSuccessfulImport(importResult)
                } else {
                    // 顯示失敗信息
                    showImportAlert(success: false, message: importResult.message)
                    showFeedback("匯入失敗", true)
                }
            } else {
                showImportAlert(success: false, message: "無法存取選擇的檔案")
            }
        } catch {
            showImportAlert(success: false, message: "檔案選擇錯誤: \(error.localizedDescription)")
        }
    }
    
    private func handleSuccessfulImport(_ importResult: (success: Bool, message: String)) {
        // 同步更新layoutManager數據
        updateLayoutManagerFromViewModel()
        
        // 執行layoutManager的數據一致性檢查
        let managerValidationResult = layoutManager.validateAndCleanData()
        
        // 重置視圖
        withAnimation(.spring()) {
            // ✅ 確保導入後更新視圖狀態
            viewState.useFixedICBoundary = false  // 切換到動態邊界模式
            viewState.resetView()
            resetView()
        }
        
        // 增加一致性檢查報告
        var successMessage = importResult.message
        if managerValidationResult.totalIssues > 0 {
            successMessage += "\n額外修復了 \(managerValidationResult.totalIssues) 個數據一致性問題"
        }
        
        // 顯示結果提示
        showImportAlert(success: true, message: successMessage)
        showFeedback("匯入成功，數據已驗證", true)
    }
    
    // MARK: - 關聯操作
    
    // 快速為選中元件建立關聯
    func quickAssociateSelectedComponents() {
        // 檢查條件
        guard canQuickAssociate else {
            showFeedback("請選擇一個Pin和一個PAD以建立關聯", false)
            return
        }
        
        let pinID = selectedPinIDs[0]
        let padID = selectedPadIDs[0]
        
        // 執行關聯操作
        let success = layoutManager.associatePinToPAD(pinID: pinID, padID: padID)
        
        // 顯示結果
        if success {
            let pinName = layoutManager.pins[pinID]?.name ?? "未知Pin"
            let padName = layoutManager.pads[padID]?.name ?? "未知PAD"
            showFeedback("已成功建立 \(pinName) 與 \(padName) 的關聯", true)
        } else {
            showFeedback("建立關聯失敗", false)
        }
    }
    
    // 快速解除選中元件的關聯
    func quickDissociateSelectedComponents() {
        // 檢查條件
        guard canQuickDissociate else {
            showFeedback("請選擇已關聯的Pin和PAD以解除關聯", false)
            return
        }
        
        let pinID = selectedPinIDs[0]
        let padID = selectedPadIDs[0]
        
        // 執行解除關聯操作
        let success = layoutManager.dissociatePinFromPAD(pinID: pinID, padID: padID)
        
        // 顯示結果
        if success {
            let pinName = layoutManager.pins[pinID]?.name ?? "未知Pin"
            let padName = layoutManager.pads[padID]?.name ?? "未知PAD"
            showFeedback("已成功解除 \(pinName) 與 \(padName) 的關聯", true)
        } else {
            showFeedback("解除關聯失敗", false)
        }
    }
}

extension ICLayoutViewModernized {
    // MARK: - 拖曳預覽處理
    
    func startDragPreview(componentID: UUID, startLocation: CGPoint, currentLocation: CGPoint) {
        // 獲取元件初始位置
        if let pad = layoutManager.pads[componentID] {
            let originalPosition = CGPoint(
                x: CGFloat(pad.centerLocateX),
                y: CGFloat(pad.centerLocateY)
            )
            
            // 啟動拖曳預覽
            dragPreviewManager.startDragging(componentID: componentID, position: originalPosition)
            
            // 如果是批量拖曳，添加所有選中元件
            if layoutManager.selectedComponents.contains(componentID) &&
               layoutManager.selectedComponents.count > 1 {
                
                for id in layoutManager.selectedComponents {
                    if let pad = layoutManager.pads[id] {
                        let position = CGPoint(
                            x: CGFloat(pad.centerLocateX),
                            y: CGFloat(pad.centerLocateY)
                        )
                        dragPreviewManager.addComponentToDrag(componentID: id, position: position)
                    }
                }
            }
            
            // 記錄內容座標系中的當前位置
            let contentPoint = screenToContentCoordinate(screenPoint: currentLocation)
            dragPreviewManager.updateCurrentPosition(contentPoint)
        }
    }
    
    func updateDragPreview(currentLocation: CGPoint) {
        // 轉換座標到內容座標系
        if let startLocation = gestureState.dragStartLocation {
            let startContentPoint = screenToContentCoordinate(screenPoint: startLocation)
            let currentContentPoint = screenToContentCoordinate(screenPoint: currentLocation)
            
            // 計算偏移量
            let offset = CGSize(
                width: currentContentPoint.x - startContentPoint.x,
                height: currentContentPoint.y - startContentPoint.y
            )
            
            // 更新拖曳預覽
            dragPreviewManager.updateDragOffset(offset)
            dragPreviewManager.updateCurrentPosition(currentContentPoint)
        }
    }
    
    func finalizeDragPreview() {
        // 如果啟用了預覽模式，顯示確認對話框
        if dragPreviewManager.previewEnabled && !dragPreviewManager.dragPreviewConfirmed {
            dragPreviewManager.promptForConfirmation()
        } else {
            // 否則直接確認拖曳
            confirmDragAction()
        }
    }
    
    func confirmDragAction() {
        // 應用預覽的移動到實際元件
        if dragPreviewManager.previewEnabled {
            for (componentID, originalPosition) in dragPreviewManager.originalPositions {
                let newPosition = CGPoint(
                    x: originalPosition.x + dragPreviewManager.dragOffset.width,
                    y: originalPosition.y + dragPreviewManager.dragOffset.height
                )
                movePADToPosition(padID: componentID, newPosition: newPosition)
            }
            
            // 記錄操作歷史
            layoutManager.recordHistory()
            showFeedback("已移動元件", true)
        }
        
        // 重置預覽狀態
        dragPreviewManager.reset()
    }

    func cancelDragAction() {
        dragPreviewManager.reset()
        showFeedback("已取消移動", true)
    }
}

extension ICLayoutViewModernized {
    // MARK: - 元件詳細資訊處理
    
    func showComponentDetails(for componentID: UUID) {
        selectedComponentID = componentID
        showingComponentDetails = true
        showFeedback("顯示元件詳情", false)
    }
    
    func hideComponentDetails() {
        selectedComponentID = nil
        showingComponentDetails = false
    }
    
    // 處理內容區域的點擊
    func handleContentTap(at location: CGPoint) {
        print("➡️ 點擊處理：位置=\(location)")
        
        // 記錄點擊位置
        gestureState.lastCursorX = location.x
        gestureState.lastCursorY = location.y
        
        // 碰撞檢測
        if let componentID = hitTest(location) {
            print("✅ 點擊到元件：\(componentID)")
            handleComponentTap(componentID)
        } else {
            print("❌ 點擊空白處")
            layoutManager.clearSelection()
            showingComponentDetails = false
            selectedComponentID = nil
            showFeedback("清除選擇", false)
        }
    }
}

