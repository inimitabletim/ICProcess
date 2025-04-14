//
//  ICLayoutViewModernized+Implementation.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/11.
//

import SwiftUI
import Combine

// MARK: - 主要混合手勢實現與整合
extension ICLayoutViewModernized {
    
    /// 初始化混合手勢系統
    func initializeHybridGestureSystem() {
        // 初始化手勢狀態
        gestureState.resetGestureState()
        gestureState.minScale = 0.1
        gestureState.maxScale = 5.0
        
        // 設置鍵盤修飾符檢測
        setupKeyModifierDetection()
        
        // 設置模式變化監聽
        setupModeChangeObservers()
        
        // 初始化反饋系統
        initializeFeedbackSystem()
        
        // 顯示歡迎提示
        showFeedback("歡迎使用IC排列視覺化工具", true)
    }
        
    /// 初始化反饋系統
    private func initializeFeedbackSystem() {
        // 預先準備觸覺反饋生成器
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
    }
    
    /// 配置主視圖的手勢處理
    func configureMainViewGestures() -> some View {
        return contentLayer
            .scaleEffect(gestureState.scale)
            .offset(gestureState.offset)
            .gesture(configureHybridGestures())
    }
    
    /// 核心內容層 - 添加混合手勢
    var contentWithHybridGestures: some View {
        ZStack {
            // 背景網格（如果啟用）
            if viewState.showGrid {
                GridBackgroundModernized()
                    .opacity(0.15)
                    .zIndex(-20) // 確保在最底層
            }
            
            // 整合了情境感知手勢的內容層
            contentLayer
                .scaleEffect(gestureState.scale)
                .offset(gestureState.offset)
                .contentShape(Rectangle()) // 確保整個區域可點擊
                .gesture(configureHybridGestures())
            
            // 📝 添加IC黑色邊框
            if viewState.showICBoundary {
                ICBoundaryView(
                    layoutManager: layoutManager,
                    useFixedBoundary: viewState.useFixedICBoundary,
                    fixedBoundarySize: viewState.fixedICSize
                )
                .scaleEffect(gestureState.scale)
                .offset(gestureState.offset)
                .zIndex(-10) // 設置為-10，確保在網格之上但在內容之下
            }
            
            // 顯示拖曳預覽層
            if dragPreviewManager.isDragging && dragPreviewManager.previewEnabled {
                DragPreviewLayer(
                    previewManager: dragPreviewManager,
                    padDimensions: layoutManager.padDimensions,
                    pads: layoutManager.pads
                )
                .scaleEffect(gestureState.scale)
                .offset(gestureState.offset)
                .zIndex(10) // 確保在內容層之上
            }
            
            // 顯示確認對話框
            if dragPreviewManager.showConfirmationDialog {
                DragConfirmDialog(
                    previewManager: dragPreviewManager,
                    onConfirm: confirmDragAction,
                    onCancel: cancelDragAction
                )
                .zIndex(20) // 確保在最上層
            }
            
            // 調試面板 (可選)
            if showDebugInfo {
                VStack {
                    Text("Scale: \(String(format: "%.2f", gestureState.scale))")
                    Text("Offset: (\(Int(gestureState.offset.width)), \(Int(gestureState.offset.height)))")
                    Text("Selected: \(layoutManager.selectedComponents.count)")
                    
                    if gestureState.isDragging {
                        Text("Dragging: \(gestureState.draggedComponentID?.uuidString.prefix(8) ?? "None")")
                    }
                    
                    if gestureState.isPanning {
                        Text("Panning")
                    }
                    
                    if gestureState.isZooming {
                        Text("Zooming")
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground).opacity(0.8))
                .cornerRadius(10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding()
                .zIndex(15) // 確保在大部分內容之上
            }
        }
    }
    
    /// 整合元件詳情面板
    func integrateComponentDetails() -> some View {
        ZStack {
            // 主內容區域
            contentWithHybridGestures
            
            // 元件詳情面板 (條件顯示)
            if showingComponentDetails, let componentID = selectedComponentID {
                // 計算詳情面板顯示位置
                let panelPosition = CGPoint(x: 160, y: 250) // 默認位置
                
                // --- 提取計算邏輯 ---
                let calculatedPanelPosition: CGPoint = {
                    var position = CGPoint(x: 160, y: 250) // 默認位置

                    // 如果元件被選中，可以根據其位置設置面板位置
                    if let pad = layoutManager.pads[componentID] {
                        let padPosition = CGPoint(
                            x: CGFloat(pad.centerLocateX),
                            y: CGFloat(pad.centerLocateY)
                        )
                        // 轉換到螢幕座標 (假設 contentToScreenCoordinate 已定義)
                        let screenPosition = contentToScreenCoordinate(contentPoint: padPosition)

                        // 避免面板超出螢幕邊界 (假設 UIScreen 可用)
                        // 注意：在 visionOS 或 macOS 上可能需要不同的方法獲取螢幕尺寸
                        #if os(iOS) || os(tvOS)
                        let screenWidth = UIScreen.main.bounds.width
                        let screenHeight = UIScreen.main.bounds.height
                        #else
                        // 為 macOS, watchOS, visionOS 提供備用值或方法
                        let screenWidth: CGFloat = 1024 // 示例值
                        let screenHeight: CGFloat = 768  // 示例值
                        #endif

                        position = CGPoint(
                            x: min(max(160, screenPosition.x), screenWidth - 160),
                            y: min(max(200, screenPosition.y), screenHeight - 200)
                        )
                    }
                    return position
                }() // 立即執行閉包來獲取計算結果
                // --- 計算邏輯結束 ---

                
                ComponentDetailsPanel(
                    componentID: componentID,
                    layoutManager: layoutManager,
                    initialPosition: panelPosition,
                    onClose: {
                        showingComponentDetails = false
                        selectedComponentID = nil
                    },
                    onEdit: {
                        // 實現編輯功能
                    }
                )
                .zIndex(30) // 確保在最上層
            }
        }
    }
    
    /// 優化型視圖更新與重繪策略
    func optimizedRerender() {
        // 優化重繪以減少性能開銷
        // 在階段一中使用基本實現，後續可優化
        
        // 強制觸發視圖模型的更新
        self.layoutManager.objectWillChange.send()
    }
        
    // 以下方法已在其他擴展中實現
    // func selectComponent(id: UUID) { ... }
    // func showComponentDetails(id: UUID) { ... }
}

// MARK: - 工具列整合

extension ICLayoutViewModernized {
    
    /// 處理工具列工具選擇操作 - 整合工具列與手勢系統
    func handleToolbarAction(_ action: SimplifiedToolbar.ToolbarAction) {
        switch action {
        case .toggleEditMode:
            viewState.isEditMode.toggle()
            // 重置手勢狀態以適應新模式
            gestureState.resetGestureState()
            showFeedback(viewState.isEditMode ? "已進入編輯模式" : "已退出編輯模式", true)
            
        case .selectTool:
            viewState.selectedTool = .select
            // 通知手勢系統切換模式
            handleToolbarToolChange()
            showFeedback("已切換到選擇工具", true)
            
        case .panTool:
            viewState.selectedTool = .pan
            // 通知手勢系統切換模式
            handleToolbarToolChange()
            showFeedback("已切換到平移工具", true)
            
        case .zoomTool:
            viewState.selectedTool = .zoom
            // 通知手勢系統切換模式
            handleToolbarToolChange()
            showFeedback("已切換到縮放工具", true)
            
        case .showFileMenu:
            // 計算檔案選單位置
            fileMenuPosition = CGPoint(x: 130, y: 130)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showFileMenu = true
            }
            
        case .showEditMenu:
            // 目前階段一不實現此功能
            showFeedback("編輯選單功能尚未實現", true)
            
        case .showViewOptions:
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showSidePanel = true
                sidePanelTab = 0 // 切換到「顯示」頁籤
            }
            
        case .toggleExtendedTools:
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showSidePanel.toggle()
            }
            
        case .showAssociationManager:
            showingAssociationManager = true
            showFeedback("開啟關聯管理器", true)
            
        default:
            // 處理其他操作...
            break
        }
    }
    
    /// 處理浮動工具面板操作 - 整合浮動工具與手勢系統
    func handleFloatingToolAction(_ action: FloatingToolPanel.ToolAction) {
        switch action {
        case .zoomIn:
            zoomIn()
            
        case .zoomOut:
            zoomOut()
            
        case .resetView:
            resetView()
            
        case .toggleGrid:
            viewState.showGrid.toggle()
            showFeedback(viewState.showGrid ? "顯示網格" : "隱藏網格", true)
            
        case .toggleLabels:
            viewState.showLabels.toggle()
            showFeedback(viewState.showLabels ? "顯示標籤" : "隱藏標籤", true)
            
        case .toggleConnections:
            viewState.showConnections.toggle()
            showFeedback(viewState.showConnections ? "顯示連線" : "隱藏連線", true)
            
        case .showSettings:
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showSidePanel = true
                sidePanelTab = 1 // 切換到「邊框」頁籤
            }
            
        case .centerSelection:
            centerOnSelection()
        }
    }
    
    /// 居中顯示選中元件
    private func centerOnSelection() {
        guard !layoutManager.selectedComponents.isEmpty else {
            showFeedback("請先選擇元件", true)
            return
        }
        
        // 計算所有選中元件的中心點
        var sumX: CGFloat = 0
        var sumY: CGFloat = 0
        var count: Int = 0
        
        for componentID in layoutManager.selectedComponents {
            if let pad = layoutManager.pads[componentID] {
                sumX += CGFloat(pad.centerLocateX)
                sumY += CGFloat(pad.centerLocateY)
                count += 1
            } else if let pin = layoutManager.pins[componentID],
                      let position = pin.getPosition(pads: layoutManager.pads) {
                sumX += CGFloat(position.x)
                sumY += CGFloat(position.y)
                count += 1
            }
        }
        
        if count > 0 {
            let centerX = sumX / CGFloat(count)
            let centerY = sumY / CGFloat(count)
            
            // 計算需要的偏移量，使中心點居中
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            
            let newOffsetX = screenWidth/2 - centerX * gestureState.scale
            let newOffsetY = screenHeight/2 - centerY * gestureState.scale
            
            // 動畫設置新偏移
            withAnimation(.spring()) {
                gestureState.offset = CGSize(width: newOffsetX, height: newOffsetY)
                gestureState.lastOffset = gestureState.offset
            }
            
            showFeedback("已居中顯示選中元件", true)
            
            // 提供觸覺反饋
            performHapticFeedback(intensity: 0.3)
        }
    }
}
