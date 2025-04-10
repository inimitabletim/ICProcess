//
//  ICLayoutViewModernized.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/1.
//

//
//  ICLayoutViewModernized.swift
//  ICEditorView
//

import SwiftUI
import Combine

/// 現代化的IC排列視覺化視圖 - 針對iPad優化
struct ICLayoutViewModernized: View, UserModeViewProtocol {
    // MARK: - 數據模型
    @ObservedObject var layoutManager: ICLayoutManager
    @ObservedObject var viewModel: ICLayoutViewModel
    @ObservedObject var viewState: ICLayoutViewState
    
    // MARK: - 狀態管理器
    @StateObject var gestureState = GestureState()
    @StateObject var dragPreviewManager = DragPreviewManager()
    
    // MARK: - 界面狀態
    @State var showModeFeedback = false
    @State var feedbackMessage = ""
    @State var isMultiSelectMode: Bool = false
    @State var rightPanelExpanded: Bool = true
    @State private var floatingToolPosition: CGPoint = CGPoint(x: 70, y: 300)
    
    // MARK: - 型別橋接層
    // 📝 增加一個型別代理，用於與期望 ToolType 的UI元件兼容
    @State private var toolTypeProxy: ICLayoutViewState.LayoutTool = .select
    
    // MARK: - 元件詳情狀態
    @State var showingComponentDetails: Bool = false
    @State var selectedComponentID: UUID? = nil
    
    // MARK: - CSV匯入狀態
    @State var isImportingCSV = false
    @State var showingImportAlert = false
    @State var importAlertMessage = ""
    @State var importAlertIsSuccess = false
    
    // MARK: - 其他視圖狀態
    @State private var showDebugInfo: Bool = false
    @State var showingBoundarySettings: Bool = false
    @State var showingAssociationManager: Bool = false
    @State private var showingQuickAssociateConfirm: Bool = false
    @State private var showingQuickDissociateConfirm: Bool = false
    @State private var associationActionMessage: String = ""
    
    @State private var showSidePanel: Bool = false
    @State private var sidePanelTab: Int = 0
    @State private var floatingPanelExpanded: Bool = false
    @State private var showFileMenu: Bool = false
    @State private var fileMenuPosition: CGPoint = .zero
    @State private var showViewOptionsMenu: Bool = false
    @State private var viewOptionsPosition: CGPoint = .zero
    
    // MARK: - 環境屬性
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - 選中的元件快速訪問
    var selectedPinIDs: [UUID] {
        layoutManager.selectedComponents.filter { layoutManager.pins[$0] != nil }
    }

    var selectedPadIDs: [UUID] {
        layoutManager.selectedComponents.filter { layoutManager.pads[$0] != nil }
    }
    
    // MARK: - 計算屬性
    var iPadMode: Bool {
        return horizontalSizeClass == .regular
    }
    
    // MARK: - 關聯操作檢查
    var canQuickAssociate: Bool {
        // 檢查是否只選中了兩個元件
        guard layoutManager.selectedComponents.count == 2 else {
            return false
        }
        
        // 檢查是否選擇了一個Pin和一個PAD
        guard selectedPinIDs.count == 1 && selectedPadIDs.count == 1 else {
            return false
        }
        
        let pinID = selectedPinIDs[0]
        let padID = selectedPadIDs[0]
        
        // 檢查元件是否存在
        guard let pin = layoutManager.pins[pinID], let pad = layoutManager.pads[padID] else {
            return false
        }
        
        // 檢查是否已經有關聯（如果有則不能再建立）
        return !pin.padIDs.contains(padID)
    }
    
    var canQuickDissociate: Bool {
        // 檢查是否只選中了兩個元件
        guard layoutManager.selectedComponents.count == 2 else {
            return false
        }
        
        // 檢查是否選擇了一個Pin和一個PAD
        guard selectedPinIDs.count == 1 && selectedPadIDs.count == 1 else {
            return false
        }
        
        let pinID = selectedPinIDs[0]
        let padID = selectedPadIDs[0]
        
        // 檢查元件是否存在
        guard let pin = layoutManager.pins[pinID], let pad = layoutManager.pads[padID] else {
            return false
        }
        
        // 檢查是否已經有關聯（如果有才能解除）
        return pin.padIDs.contains(padID)
    }
    
    // MARK: - 主視圖修改
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景層
                Color(UIColor.systemBackground)
                
                // 主內容層
                VStack(spacing: 0) {
                    // 頂部簡化工具列
                    SimplifiedToolbar(
                        selectedTool: $toolTypeProxy,
                        isEditMode: $viewState.isEditMode,
                        showExtendedTools: $showSidePanel,
                        onAction: handleToolbarAction
                    )
                    
                    // 主內容區域
                    ZStack {
                        // 主要內容視圖
                        contentArea(geometry: geometry)
                        
                        // 右側可收合的工具面板 - 使用新的 ViewOptionsPanel
                        if showSidePanel {
                            ViewOptionsPanel(
                                viewState: viewState,
                                isExpanded: $showSidePanel,
                                selectedTab: $sidePanelTab,
                                onClose: { showSidePanel = false }
                            )
                            .transition(.move(edge: .trailing))
                            .position(x: geometry.size.width - 140, y: geometry.size.height / 2)
                            .zIndex(20)
                        }
                        
                        // 檔案選單
                        if showFileMenu {
                            FileMenuView(onAction: handleFileAction)
                                .position(fileMenuPosition)
                                .transition(.scale.combined(with: .opacity))
                                .zIndex(30)
                        }
                        
                        // 懸浮工具面板
                        FloatingToolPanel(
                            position: $floatingToolPosition,
                            isExpanded: $floatingPanelExpanded,
                            onAction: handleFloatingToolAction
                        )
                        .zIndex(25)
                    }
                    
                    // 簡化的底部信息欄 - 僅保留必要信息
                    HStack {
                        // 左側：選中計數
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                            
                            Text("已選: \(layoutManager.selectedComponents.count)")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .padding(.leading, 16)
                        
                        Spacer()
                        
                        // 右側：縮放比例
                        Text("縮放: \(Int(gestureState.scale * 100))%")
                            .font(.system(size: 14))
                            .padding(.trailing, 16)
                    }
                    .frame(height: 36)
                    .background(Color(UIColor.secondarySystemBackground))
                }
                
                // 操作反饋提示
                if showModeFeedback {
                    FeedbackToast(message: feedbackMessage)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(100)
                }
            }
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                initializeViewState()
            }
            .fileImporter(
                isPresented: $isImportingCSV,
                allowedContentTypes: [.commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                handleCSVImport(result: result)
            }
        }
    }
    
    // MARK: - 處理工具列操作
    private func handleToolbarAction(_ action: SimplifiedToolbar.ToolbarAction) {
        switch action {
        case .toggleEditMode:
            viewState.isEditMode.toggle()
            showFeedback(viewState.isEditMode ? "已進入編輯模式" : "已退出編輯模式", true)
            
        case .selectTool:
            toolTypeProxy = .select
            viewState.selectedTool = .select
            showFeedback("已切換到選擇工具", true)
            
        case .panTool:
            toolTypeProxy = .pan
            viewState.selectedTool = .pan
            showFeedback("已切換到平移工具", true)
            
        case .zoomTool:
            toolTypeProxy = .zoom
            viewState.selectedTool = .zoom
            showFeedback("已切換到縮放工具", true)
            
        case .showFileMenu:
            // 計算檔案選單位置
            fileMenuPosition = CGPoint(x: 130, y: 130)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showFileMenu = true
            }
            
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

    // MARK: - 處理檔案操作
    private func handleFileAction(_ action: FileMenuView.FileAction) {
        switch action {
        case .importCSV:
            isImportingCSV = true
            showFileMenu = false
            
        case .exportCSV:
            // 處理匯出操作
            showFeedback("匯出 CSV 功能尚未實現", true)
            showFileMenu = false
            
        case .saveLayout:
            // 處理儲存佈局操作
            showFeedback("儲存佈局功能尚未實現", true)
            showFileMenu = false
            
        case .loadLayout:
            // 處理載入佈局操作
            showFeedback("載入佈局功能尚未實現", true)
            showFileMenu = false
            
        case .dismiss:
            withAnimation {
                showFileMenu = false
            }
        }
    }

    // MARK: - 處理懸浮工具操作
    private func handleFloatingToolAction(_ action: FloatingToolPanel.ToolAction) {
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

    // MARK: - 居中顯示選中元件
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
                sumX += position.x
                sumY += position.y
                count += 1
            }
        }
        
        if count > 0 {
            let centerX = sumX / CGFloat(count)
            let centerY = sumY / CGFloat(count)
            
            // 計算需要的偏移量，使中心點居中
            let geometry = UIScreen.main.bounds
            let screenCenterX = geometry.width / 2
            let screenCenterY = geometry.height / 2
            
            let offsetX = screenCenterX - centerX * gestureState.scale
            let offsetY = screenCenterY - centerY * gestureState.scale
            
            // 設置偏移
            withAnimation(.spring()) {
                gestureState.offset = CGSize(width: offsetX, height: offsetY)
                gestureState.lastOffset = gestureState.offset
            }
            
            showFeedback("已居中顯示選中元件", true)
        }
    }
    
    // MARK: - 內容區域
    private func contentArea(geometry: GeometryProxy) -> some View {
        ZStack {
            // 背景網格（如果啟用）
            if viewState.showGrid {
                GridBackgroundModernized()
                    .opacity(0.15)
                    .zIndex(-20) // 確保在最底層
            }
            
            // 主要內容層
            contentLayer
                .scaleEffect(gestureState.scale)
                .offset(gestureState.offset)
                .gesture(configureGestures())
                .contentShape(Rectangle())
                .onTapGesture { location in
                    handleContentTap(at: location)
                }
            
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
            
            // 調試面板
            if showDebugInfo {
                VStack {
                    Text("Scale: \(String(format: "%.2f", gestureState.scale))")
                    Text("Offset: (\(Int(gestureState.offset.width)), \(Int(gestureState.offset.height)))")
                    Text("Selected: \(layoutManager.selectedComponents.count)")
                }
                .padding()
                .background(Color(UIColor.systemBackground).opacity(0.8))
                .cornerRadius(10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding()
            }
        }
    }
    
    // MARK: - 內容層
    private var contentLayer: some View {
        ZStack {
            // 繪製PAD
            ForEach(Array(layoutManager.pads.keys), id: \.self) { padID in
                if let pad = layoutManager.pads[padID] {
                    PADViewModernized(
                        pad: pad,
                        dimension: pad.padDimensionID != nil ? layoutManager.padDimensions[pad.padDimensionID!] : nil,
                        isSelected: layoutManager.selectedComponents.contains(padID),
                        showLabel: viewState.showLabels
                    )
                }
            }
            
            // 繪製連接線
            if viewState.showConnections {
                renderEnhancedConnections()
            }
            
            // 繪製Pin
            ForEach(Array(layoutManager.pins.keys), id: \.self) { pinID in
                if let pin = layoutManager.pins[pinID],
                   let position = getPinPosition(for: pin) {
                    PinViewModernized(
                        pin: pin,
                        position: position,
                        isSelected: layoutManager.selectedComponents.contains(pinID),
                        showLabel: viewState.showLabels
                    )
                }
            }
        }
    }
    
    // MARK: - 右側面板
    private var rightSidePanel: some View {
        VStack(spacing: 20) {
            // 視圖操作工具
            VStack(spacing: 12) {
                ModernToolbarButton(icon: "plus.magnifyingglass", title: "放大") {
                    zoomIn()
                }
                
                ModernToolbarButton(icon: "minus.magnifyingglass", title: "縮小") {
                    zoomOut()
                }
                
                ModernToolbarButton(icon: "arrow.counterclockwise", title: "重置") {
                    resetView()
                }
                
                // 調試開關
                ModernToolbarButton(
                    icon: showDebugInfo ? "info.circle.fill" : "info.circle",
                    title: "調試",
                    isActive: showDebugInfo
                ) {
                    showDebugInfo.toggle()
                }
            }
            .padding(.vertical, 16)
            
            Divider()
                .padding(.horizontal, 16)
            
            // 視圖選項
            VStack(spacing: 12) {
                ModernToolbarButton(
                    icon: viewState.showLabels ? "tag.fill" : "tag",
                    title: "標籤",
                    isActive: viewState.showLabels
                ) {
                    viewState.showLabels.toggle()
                    showFeedback(viewState.showLabels ? "顯示標籤" : "隱藏標籤", true)
                }
                
                ModernToolbarButton(
                    icon: viewState.showConnections ? "link" : "link.slash",
                    title: "連線",
                    isActive: viewState.showConnections
                ) {
                    viewState.showConnections.toggle()
                    showFeedback(viewState.showConnections ? "顯示連線" : "隱藏連線", true)
                }
                
                ModernToolbarButton(
                    icon: viewState.showGrid ? "grid" : "square",
                    title: "網格",
                    isActive: viewState.showGrid
                ) {
                    viewState.showGrid.toggle()
                    showFeedback(viewState.showGrid ? "顯示網格" : "隱藏網格", true)
                }
            }
            .padding(.vertical, 16)
            
            Divider()
                .padding(.horizontal, 16)

            // IC邊框選項
            VStack(spacing: 12) {
                Text("IC邊框")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                
                // 顯示/隱藏邊框
                ModernToolbarButton(
                    icon: viewState.showICBoundary ? "square.fill" : "square",
                    title: "顯示邊框",
                    isActive: viewState.showICBoundary
                ) {
                    viewState.showICBoundary.toggle()
                    showFeedback(viewState.showICBoundary ? "顯示IC邊框" : "隱藏IC邊框", true)
                }
                
                // 固定/動態邊框切換
                ModernToolbarButton(
                    icon: viewState.useFixedICBoundary ? "square.dashed" : "square.on.square",
                    title: viewState.useFixedICBoundary ? "固定邊框" : "動態邊框",
                    isActive: viewState.useFixedICBoundary
                ) {
                    viewState.useFixedICBoundary.toggle()
                    showFeedback(
                        viewState.useFixedICBoundary ? "使用固定尺寸邊框" : "使用動態計算邊框",
                        true
                    )
                }
                
                // 邊框設定按鈕
                ModernToolbarButton(
                    icon: "slider.horizontal.3",
                    title: "邊框設定",
                    isActive: false
                ) {
                    showingBoundarySettings = true
                }
            }
            .padding(.vertical, 16)
            
            // 新增：關聯管理快捷工具
            VStack(spacing: 12) {
                Text("關聯操作")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                
                // 開啟關聯管理器
                ModernToolbarButton(
                    icon: "link.circle",
                    title: "關聯管理",
                    isActive: showingAssociationManager
                ) {
                    showingAssociationManager = true
                    showFeedback("開啟關聯管理器", true)
                }
                
                // 快速關聯選中元件
                ModernToolbarButton(
                    icon: "link.badge.plus",
                    title: "建立關聯",
                    isActive: canQuickAssociate
                ) {
                    quickAssociateSelectedComponents()
                }
                .disabled(!canQuickAssociate)
                
                // 快速解除選中元件的關聯
                ModernToolbarButton(
                    icon: "link.badge.minus",
                    title: "解除關聯",
                    isActive: canQuickDissociate
                ) {
                    quickDissociateSelectedComponents()
                }
                .disabled(!canQuickDissociate)
            }
            .padding(.vertical, 16)
            
            Spacer()
        }
        .padding(.top, 16)
    }
    
    // MARK: - 底部信息欄
    private func bottomInfoBar(geometry: GeometryProxy) -> some View {
        HStack {
            // 左側元件計數
            HStack(spacing: 16) {
                // Pin計數
                HStack(spacing: 6) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.blue)
                    
                    Text("Pin: \(layoutManager.pins.count)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                // PAD計數
                HStack(spacing: 6) {
                    Image(systemName: "square.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                    
                    Text("PAD: \(layoutManager.pads.count)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                // 選中計數
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    
                    Text("已選: \(layoutManager.selectedComponents.count)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            Spacer()
            
            // 右側視圖比例與位置信息
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 12))
                    Text("比例: \(Int(gestureState.scale * 100))%")
                        .font(.system(size: 14, weight: .medium))
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "move.3d")
                        .font(.system(size: 12))
                    Text("位置: (\(Int(gestureState.offset.width)), \(Int(gestureState.offset.height)))")
                        .font(.system(size: 14, weight: .medium))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - 連接線渲染
    func renderEnhancedConnections() -> some View {
        ZStack {
            // 繪製所有連線
            ForEach(Array(layoutManager.pins.keys), id: \.self) { pinID in
                if let pin = layoutManager.pins[pinID],
                   let pinPosition = getPinPosition(for: pin) {
                    // 繪製此Pin的所有連線
                    ForEach(pin.padIDs, id: \.self) { padID in
                        if let pad = layoutManager.pads[padID] {
                            let padPosition = CGPoint(
                                x: CGFloat(pad.centerLocateX),
                                y: CGFloat(pad.centerLocateY)
                            )
                            
                            // 決定連線樣式
                            let isSelected = layoutManager.selectedComponents.contains(pinID) ||
                                           layoutManager.selectedComponents.contains(padID)
                            
                            // 使用增強的連線視圖
                            EnhancedConnectionView(
                                from: pinPosition,
                                to: padPosition,
                                lineType: .curved,
                                style: isSelected ? .selected : .normal,
                                animating: isSelected
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - UserModeViewProtocol 實現
    
    func selectComponent(id: UUID) {
        handleComponentTap(id)
    }
    
    func showComponentDetails(id: UUID) {
        selectedComponentID = id
        showingComponentDetails = true
    }
}

