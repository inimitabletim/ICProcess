//
//  ICLayoutUserView.swift
//  ICEditorView
//
//  Created by TimChi on 2025/3/27.
//

import SwiftUI

// 確保有 LayoutTool 定義
enum LayoutTool {
    case select, pan, zoom, addPin, addPad, connect
}

struct ICLayoutUserView: View, UserModeViewProtocol {
    @ObservedObject var layoutManager: ICLayoutManager
    @ObservedObject var viewModel: ICLayoutViewModel
    @ObservedObject var viewState: ICLayoutViewState
    
    // 使用基本狀態而非 GestureState
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    @State private var isZooming: Bool = false
    @State private var lastTapLocation: CGPoint? = nil
    
    // 調試狀態變數
    @State private var debugText: String = "等待操作..."
    @State private var showDebugInfo: Bool = true
    
    // 界面狀態
    @State private var showModeFeedback = false
    @State private var feedbackMessage = ""
    @State private var isDraggingComponent = false
    
    // 面板展開狀態
    @State private var isDirectionPanelExpanded: Bool = false
    @State private var isViewOptionsPanelExpanded: Bool = false
    
    // csv匯入
    @State private var isImportingCSV = false
    @State private var showingImportAlert = false
    @State private var importAlertMessage = ""
    @State private var importAlertIsSuccess = false
    
    // 通過GeometryReader獲取視圖尺寸
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    // 現代化的公司頂部導航欄
                    companyTopBar
                        .frame(height: 60)
                    
                    ZStack {
                        // 背景
                        ICColors.background
                            .ignoresSafeArea()
                        
                        // 主內容區域
                        ZStack {
                            // 網格背景
                            if viewState.showGrid {
                                GridBackgroundView(viewSize: geometry.size)
                            }
                            
                            // 內容層 - 使用簡化的手勢處理
                            contentLayer
                                .scaleEffect(scale)
                                .offset(offset)
                                // 📝 分離不同的手勢以避免衝突
                                // 1. 平移手勢：優先處理
                                .gesture(
                                    DragGesture(minimumDistance: 1)
                                        .onChanged { value in
                                            updateDebugText("拖動中: \(Int(value.translation.width)), \(Int(value.translation.height))")
                                            
                                            // 記錄開始位置（用於元件選擇判定）
                                            if !isDragging {
                                                isDragging = true
                                                lastTapLocation = value.startLocation
                                                print("📍 拖動開始位置：\(value.startLocation)")
                                            }
                                            
                                            // 判斷是否點擊到元件
                                            if !isDraggingComponent && isDragging && lastTapLocation != nil {
                                                if let componentID = hitTest(lastTapLocation!) {
                                                    isDraggingComponent = true
                                                    layoutManager.toggleSelection(id: componentID)
                                                    showFeedback("已選擇元件: \(componentID)")
                                                    print("🎯 選擇元件: \(componentID)")
                                                }
                                            }
                                            
                                            // 如果是在拖動元件
                                            if isDraggingComponent && viewState.isEditMode {
                                                // 移動選中的元件
                                                moveSelectedComponents(translation: value.translation)
                                            } else {
                                                // 否則平移視圖
                                                offset = CGSize(
                                                    width: lastOffset.width + value.translation.width,
                                                    height: lastOffset.height + value.translation.height
                                                )
                                            }
                                        }
                                        .onEnded { value in
                                            // 更新最後的偏移
                                            if !isDraggingComponent {
                                                lastOffset = offset
                                            }
                                            
                                            // 計算總移動距離
                                            let distanceMoved = sqrt(
                                                pow(value.translation.width, 2) +
                                                pow(value.translation.height, 2)
                                            )
                                            
                                            // 提供反饋
                                            if distanceMoved > 5 {
                                                if isDraggingComponent {
                                                    showFeedback("移動元件完成")
                                                    updateDebugText("移動元件完成")
                                                } else {
                                                    showFeedback("平移視圖完成")
                                                    updateDebugText("平移視圖完成")
                                                }
                                            }
                                            
                                            // 重置狀態
                                            isDragging = false
                                            isDraggingComponent = false
                                            lastTapLocation = nil
                                            print("✅ 手勢操作完成")
                                        }
                                )
                                // 2. 縮放手勢：輔助處理
                                .gesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            updateDebugText("縮放中: \(value)")
                                            isZooming = true
                                            // 計算新的縮放比例並限制範圍
                                            let newScale = lastScale * value
                                            scale = min(max(0.1, newScale), 5.0)
                                        }
                                        .onEnded { _ in
                                            // 更新最後的縮放值
                                            lastScale = scale
                                            updateDebugText("縮放結束: \(scale)")
                                            
                                            // 提供反饋
                                            showFeedback("縮放比例: \(Int(scale * 100))%")
                                            
                                            // 重置縮放狀態
                                            isZooming = false
                                        }
                                )
                                // 3. 添加單獨的點擊手勢
                                .overlay(
                                    Color.clear
                                        .contentShape(Rectangle())
                                        .onTapGesture { location in
                                            print("🖱️ 點擊位置：\(location)")
                                            updateDebugText("點擊位置：\(Int(location.x)), \(Int(location.y))")
                                            
                                            let contentLocation = screenToContentCoordinate(screenPoint: location)
                                            print("📌 內容位置：\(contentLocation)")
                                            
                                            if let componentID = hitTest(location) {
                                                print("🎯 點擊到元件：\(componentID)")
                                                updateDebugText("選擇元件: \(componentID)")
                                                layoutManager.toggleSelection(id: componentID)
                                                showFeedback("已選擇元件")
                                            }
                                        }
                                )
                        }
                        
                        // 調試信息顯示
                        if showDebugInfo {
                            VStack {
                                Text(debugText)
                                    .font(.system(size: 14))
                                    .padding(8)
                                    .background(Color.black.opacity(0.7))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                
                                Spacer()
                            }
                            .padding(.top, 10)
                        }
                        
                        // 操作反饋提示
                        if showModeFeedback {
                            feedbackToast
                        }
                        
                        // 模式指示器
                        VStack {
                            modeIndicator
                                .padding(.top, 10)
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 20)
                    }
                }
                
                // 右側工具面板定位在右上角
                VStack {
                    rightToolPanel
                        .padding(.top, 75) // 避開頂部導航欄
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                
                // 浮動控制區定位在右下角
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        floatingControlArea
                    }
                }
                
                // 底部信息面板
                VStack {
                    Spacer()
                    bottomInfoPanel(geometry: geometry)
                }
                
                // 🌟 調試用手勢觸點指示器
                if let tapLocation = lastTapLocation {
                    Circle()
                        .fill(Color.red.opacity(0.5))
                        .frame(width: 20, height: 20)
                        .position(tapLocation)
                }
            }
            .edgesIgnoringSafeArea(.bottom)
            .onAppear {
                // 初始化視圖狀態
                initializeViewState()
                
                // 輸出初始化信息，有助於診斷
                print("📱 視圖已初始化: 模式=\(viewState.selectedTool), 縮放=\(viewState.scale)")
                updateDebugText("視圖已初始化")
            }
            // 同步狀態 - 使用 onChange API
            .onChange(of: scale) { newValue, _ in
                syncScaleToViewState(newValue)
            }
            .onChange(of: offset) { newValue, _ in
                syncOffsetToViewState(newValue)
            }
            .onChange(of: viewState.scale) { newValue, _ in
                syncViewStateScaleToLocal(newValue)
            }
            .onChange(of: viewState.offset) { newValue, _ in
                syncViewStateOffsetToLocal(newValue)
            }
            // 當工具模式改變時，重置狀態
            .onChange(of: viewState.selectedTool) { _, _ in
                resetGestureState()
            }
            .onChange(of: viewState.isEditMode) { _, _ in
                resetGestureState()
            }
        }
    }
    
    // MARK: - 調試輔助方法
    
    /// 更新調試文本
    private func updateDebugText(_ text: String) {
        debugText = text
        print("🔍 \(text)")
    }
    
    

    // MARK: - 原生手勢處理方法
    
    /// 根據當前模式獲取適合的手勢
    private func getGestureForCurrentMode() -> AnyGesture<Void> {
        switch viewState.selectedTool {
        case .pan:
            // 平移工具模式: 僅允許平移
            return panGesture.eraseToAnyGesture()
        case .zoom:
            // 縮放工具模式: 僅允許縮放
            return magnificationGesture.eraseToAnyGesture()
        case .select:
            // 選擇工具模式: 允許平移和縮放，但優先處理選擇
            return SimultaneousGesture(magnificationGesture, panGesture).eraseToAnyGesture()
        default:
            // 默認模式: 允許平移和縮放
            return SimultaneousGesture(magnificationGesture, panGesture).eraseToAnyGesture()
        }
    }

    
    /// 縮放手勢
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                // 如果在編輯模式且正在拖動元件，則不縮放
                if viewState.isEditMode && isDraggingComponent {
                    return
                }
                
                isZooming = true
                // 計算新的縮放比例並限制範圍
                let newScale = lastScale * value
                scale = min(max(0.1, newScale), 5.0)
            }
            .onEnded { _ in
                // 更新最後的縮放值
                lastScale = scale
                
                // 提供反饋
                showFeedback("縮放比例: \(Int(scale * 100))%")
                
                // 重置縮放狀態
                isZooming = false
            }
    }
    
    /// 平移手勢
    private var panGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                // 如果正在縮放，不執行平移
                if isZooming {
                    return
                }
                
                if !isDragging {
                    isDragging = true
                    lastTapLocation = value.startLocation
                    
                    // 檢查是否點擊到元素
                    if viewState.isEditMode || viewState.selectedTool == .select {
                        if let componentID = hitTest(value.startLocation) {
                            isDraggingComponent = true
                            // 在編輯模式下選中元素
                            layoutManager.toggleSelection(id: componentID)
                            showFeedback("已選擇元件")
                            return
                        }
                    }
                }
                
                // 如果是在拖動元件
                if isDraggingComponent && viewState.isEditMode {
                    // 移動選中的元件
                    moveSelectedComponents(translation: value.translation)
                } else {
                    // 否則平移視圖
                    offset = CGSize(
                        width: lastOffset.width + value.translation.width,
                        height: lastOffset.height + value.translation.height
                    )
                }
            }
            .onEnded { value in
                // 更新最後的偏移
                if !isDraggingComponent {
                    lastOffset = offset
                }
                
                // 計算總移動距離
                let distanceMoved = sqrt(
                    pow(value.translation.width, 2) +
                    pow(value.translation.height, 2)
                )
                
                // 提供反饋
                if distanceMoved > 5 {
                    if isDraggingComponent {
                        showFeedback("移動元件")
                    } else {
                        showFeedback("平移視圖")
                    }
                }
                
                // 重置狀態
                isDragging = false
                isDraggingComponent = false
                lastTapLocation = nil
            }
    }
    
    // MARK: - 初始化與同步方法
    
    /// 初始化視圖狀態
    private func initializeViewState() {
        // 設置初始縮放和偏移
        scale = viewState.scale
        lastScale = viewState.scale
        offset = viewState.offset
        lastOffset = viewState.lastOffset
    }
    
    /// 同步縮放狀態到ViewState
    private func syncScaleToViewState(_ newValue: CGFloat) {
        viewState.scale = newValue
        viewState.lastScale = lastScale
    }
    
    
    /// 同步偏移狀態到ViewState
    private func syncOffsetToViewState(_ newValue: CGSize) {
        viewState.offset = newValue
        viewState.lastOffset = lastOffset
    }
    
    
    /// 同步ViewState縮放狀態到本地狀態
    private func syncViewStateScaleToLocal(_ newValue: CGFloat) {
        if scale != newValue {
            scale = newValue
            lastScale = newValue
        }
    }
    
    /// 同步ViewState偏移狀態到本地狀態
    private func syncViewStateOffsetToLocal(_ newValue: CGSize) {
        if offset != newValue {
            offset = newValue
            lastOffset = newValue
        }
    }
    
    /// 重置手勢狀態
    private func resetGestureState() {
        isDragging = false
        isZooming = false
        isDraggingComponent = false
        lastTapLocation = nil
        updateDebugText("手勢狀態已重置")
    }

    // MARK: - 現代化公司頂部導航欄
    
    private var companyTopBar: some View {
        HStack(spacing: 0) {
            // 中央操作按鈕組
            topBarButtonGroup
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.white, Color(white: 0.97)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var topBarButtonGroup: some View {
        HStack(spacing: 0) {
            // 文件操作區域
            ToolGroup(title: "文件") {
                ToolButton(icon: "square.and.arrow.down", label: "匯入") {
                    // 觸發文件選擇器
                    isImportingCSV = true
                }
                // 添加 fileImporter
                .fileImporter(
                    isPresented: $isImportingCSV,
                    allowedContentTypes: [.commaSeparatedText], // CSV 檔案類型
                    allowsMultipleSelection: false
                ) { result in
                    // 處理檔案選擇結果
                    handleCSVImport(result: result)
                }
                // 添加匯入結果警告
                .alert(isPresented: $showingImportAlert) {
                    Alert(
                        title: Text(importAlertIsSuccess ? "匯入成功" : "匯入失敗"),
                        message: Text(importAlertMessage),
                        dismissButton: .default(Text("確定"))
                    )
                }

                
                ToolButton(icon: "square.and.arrow.up", label: "匯出") {
                    // 實際匯出功能
                    showFeedback("匯出檔案")
                }
            }
            
            // 編輯操作區域
            ToolGroup(title: "編輯") {
                ToolButton(icon: "arrow.uturn.backward", label: "復原") {
                    layoutManager.undo()
                    showFeedback("復原")
                }
                
                ToolButton(icon: "arrow.uturn.forward", label: "重做") {
                    layoutManager.redo()
                    showFeedback("重做")
                }
            }
            
            // 視圖模式區域
            ToolGroup(title: "視圖") {
                ToolButton(
                    icon: viewState.isEditMode ? "pencil.circle.fill" : "pencil.circle",
                    label: viewState.isEditMode ? "編輯中" : "編輯",
                    isActive: viewState.isEditMode
                ) {
                    viewState.isEditMode.toggle()
                    showFeedback(viewState.isEditMode ? "編輯模式" : "瀏覽模式")
                    // 重置手勢狀態
                    resetGestureState()
                }
                
                ToolButton(
                    icon: "hand.point.up.fill",
                    label: "選擇",
                    isActive: viewState.selectedTool == .select
                ) {
                    viewState.selectedTool = .select
                    showFeedback("選擇工具")
                    // 重置手勢狀態
                    resetGestureState()
                }
                
                ToolButton(
                    icon: "hand.draw.fill",
                    label: "平移",
                    isActive: viewState.selectedTool == .pan
                ) {
                    viewState.selectedTool = .pan
                    showFeedback("平移工具")
                    // 重置手勢狀態
                    resetGestureState()
                }
            }
        }
    }
    
    // 在 ICLayoutUserView 中添加處理函數
    private func handleCSVImport(result: Result<[URL], Error>) {
        do {
            // 獲取選擇的檔案 URL
            let selectedFiles = try result.get()
            
            // 確保選擇了檔案
            guard let selectedFile = selectedFiles.first else {
                showImportAlert(success: false, message: "未選擇檔案")
                return
            }
            
            // 獲取檔案存取權限
            if selectedFile.startAccessingSecurityScopedResource() {
                defer { selectedFile.stopAccessingSecurityScopedResource() }
                
                // 使用匯入功能處理檔案
                let importResult = viewModel.loadFromCSV(url: selectedFile)
                
                // 如果成功，更新 layoutManager 中的數據
                if importResult.success {
                    // 同步更新 layoutManager 數據
                    updateLayoutManagerFromViewModel()
                    
                    // 重置視圖
                    withAnimation(.spring()) {
                        viewState.resetView()
                        resetView()
                    }
                }
                
                // 顯示結果提示
                showImportAlert(success: importResult.success, message: importResult.message)
                showFeedback(importResult.success ? "匯入成功" : "匯入失敗")
            } else {
                showImportAlert(success: false, message: "無法存取選擇的檔案")
            }
        } catch {
            showImportAlert(success: false, message: "檔案選擇錯誤: \(error.localizedDescription)")
        }
    }

    // 顯示匯入結果提示
    private func showImportAlert(success: Bool, message: String) {
        importAlertIsSuccess = success
        importAlertMessage = message
        showingImportAlert = true
    }

    // 從 ViewModel 更新 LayoutManager 數據
    private func updateLayoutManagerFromViewModel() {
        // 將 ViewModel 中的數據轉換為 LayoutManager 需要的格式
        var pinDict: [UUID: ModelPin] = [:]
        var padDict: [UUID: ModelPAD] = [:]
        
        // 轉換 Pin 數據
        for pin in viewModel.pins {
            pinDict[pin.id] = pin
        }
        
        // 轉換 PAD 數據
        for pad in viewModel.pads {
            padDict[pad.id] = pad
        }
        
        // 更新 LayoutManager 數據
        layoutManager.pins = pinDict
        layoutManager.pads = padDict
        layoutManager.padDimensions = viewModel.padDimensions
        
        // 記錄歷史
        layoutManager.recordHistory()
    }
    
   
    // MARK: - 視圖內容
    
    /// 主內容層 - 顯示所有IC元件
    private var contentLayer: some View {
        ZStack {
            // 繪製PAD
            ForEach(Array(layoutManager.pads.keys), id: \.self) { padID in
                if let pad = layoutManager.pads[padID] {
                    PADView(
                        pad: pad,
                        dimension: pad.padDimensionID != nil ? layoutManager.padDimensions[pad.padDimensionID!] : nil,
                        isSelected: layoutManager.selectedComponents.contains(padID),
                        showLabel: viewState.showLabels
                    )
                }
            }
            
            // 繪製連接線
            if viewState.showConnections {
                ForEach(Array(layoutManager.pins.keys), id: \.self) { pinID in
                    if let pin = layoutManager.pins[pinID],
                       let pinPosition = getPinPosition(for: pin) {
                        ForEach(pin.padIDs, id: \.self) { padID in
                            if let pad = layoutManager.pads[padID] {
                                ConnectionView(
                                    from: pinPosition,
                                    to: CGPoint(x: CGFloat(pad.centerLocateX), y: CGFloat(pad.centerLocateY))
                                )
                            }
                        }
                    }
                }
            }
            
            // 繪製Pin
            ForEach(Array(layoutManager.pins.keys), id: \.self) { pinID in
                if let pin = layoutManager.pins[pinID],
                   let position = getPinPosition(for: pin) {
                    PinView(
                        pin: pin,
                        position: position,
                        isSelected: layoutManager.selectedComponents.contains(pinID),
                        showLabel: viewState.showLabels
                    )
                }
            }
        }
    }
    
    /// 右側工具面板
    private var rightToolPanel: some View {
        VStack(spacing: 15) {
            // 視圖操作工具
            VStack(spacing: 8) {
                ToolbarButton(icon: "plus.magnifyingglass", action: {
                    zoomIn()
                }, label: "放大")
                
                ToolbarButton(icon: "minus.magnifyingglass", action: {
                    zoomOut()
                }, label: "縮小")
                
                ToolbarButton(icon: "arrow.counterclockwise", action: {
                    resetView()
                }, label: "重置")
                
                // 新增：調試開關
                ToolbarButton(
                    icon: showDebugInfo ? "info.circle.fill" : "info.circle",
                    action: {
                        showDebugInfo.toggle()
                    },
                    label: "調試",
                    isActive: showDebugInfo
                )
            }
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.9))
                    .shadow(color: Color.black.opacity(0.1), radius: 2)
            )
            
            Spacer()
        }
        .frame(width: 60)
        .padding(.trailing, 8)
    }
    
    private var floatingControlArea: some View {
        VStack(alignment: .trailing, spacing: 10) {
            // 方向控制面板
            FloatingControlPanel(
                isExpanded: $isDirectionPanelExpanded,
                icon: "arrow.up.and.down.and.arrow.left.and.right",
                label: "方向"
            ) {
                // 方向控制內容
                VStack(spacing: 8) {
                    ToolbarButton(icon: "arrow.up", action: {
                        moveView(direction: .up)
                    }, label: "")
                    
                    HStack(spacing: 8) {
                        ToolbarButton(icon: "arrow.left", action: {
                            moveView(direction: .left)
                        }, label: "")
                        
                        ToolbarButton(icon: "arrow.right", action: {
                            moveView(direction: .right)
                        }, label: "")
                    }
                    
                    ToolbarButton(icon: "arrow.down", action: {
                        moveView(direction: .down)
                    }, label: "")
                }
            }
            
            // 視圖選項面板
            FloatingControlPanel(
                isExpanded: $isViewOptionsPanelExpanded,
                icon: "eye",
                label: "選項"
            ) {
                // 視圖選項內容
                VStack(spacing: 8) {
                    ToolbarButton(
                        icon: viewState.showLabels ? "tag.fill" : "tag",
                        action: {
                            viewState.showLabels.toggle()
                            showFeedback(viewState.showLabels ? "顯示標籤" : "隱藏標籤")
                        },
                        label: "標籤",
                        isActive: viewState.showLabels
                    )
                    
                    ToolbarButton(
                        icon: viewState.showConnections ? "link" : "link.badge.plus",
                        action: {
                            viewState.showConnections.toggle()
                            showFeedback(viewState.showConnections ? "顯示連線" : "隱藏連線")
                        },
                        label: "連線",
                        isActive: viewState.showConnections
                    )
                    
                    ToolbarButton(
                        icon: viewState.showGrid ? "grid" : "square",
                        action: {
                            viewState.showGrid.toggle()
                            showFeedback(viewState.showGrid ? "顯示網格" : "隱藏網格")
                        },
                        label: "網格",
                        isActive: viewState.showGrid
                    )
                }
            }
        }
        .padding(.trailing, 16)
        .padding(.bottom, 60) // 確保不會被底部信息面板覆蓋
    }
        
    /// 底部信息面板
    private func bottomInfoPanel(geometry: GeometryProxy) -> some View {
        HStack {
            // 左側元件計數
            HStack(spacing: 15) {
                // Pin計數
                HStack(spacing: 6) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.blue)
                    
                    Text("Pin: \(layoutManager.pins.count)")
                        .font(.system(size: 12))
                        .foregroundColor(.primary)
                }
                
                // PAD計數
                HStack(spacing: 6) {
                    Image(systemName: "square.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                    
                    Text("PAD: \(layoutManager.pads.count)")
                        .font(.system(size: 12))
                        .foregroundColor(.primary)
                }
                
                // 選中計數
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    
                    Text("已選: \(layoutManager.selectedComponents.count)")
                        .font(.system(size: 12))
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.8))
            .cornerRadius(6)
            
            Spacer()
            
            // 右側視圖比例與位置信息
            Text("比例: \(Int(scale * 100))% | 偏移: (\(Int(offset.width)), \(Int(offset.height)))")
                .font(.system(size: 12))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.8))
                .cornerRadius(6)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 15)
    }
    
    /// 反饋提示組件
    private var feedbackToast: some View {
        Text(feedbackMessage)
            .font(.system(size: 14, weight: .medium))
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.7))
                    .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
            )
            .foregroundColor(.white)
            .cornerRadius(8)
            .transition(.opacity)
            .zIndex(100)
    }
    
    /// 模式指示器 - 顯示當前工具模式
    private var modeIndicator: some View {
        HStack(spacing: 8) {
            // 當前工具模式圖標
            Image(systemName: toolModeIcon)
                .font(.system(size: 14))
                .foregroundColor(.white)
            
            // 模式名稱
            Text(toolModeName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(toolModeColor.opacity(0.8))
                .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 1)
        )
    }
    
    // MARK: - 座標轉換方法
    
    /// 座標轉換: 螢幕座標到內容座標
    private func screenToContentCoordinate(screenPoint: CGPoint) -> CGPoint {
        // 記錄轉換過程
        print("💻 座標轉換 - 螢幕點: \(screenPoint), 偏移: \(offset), 縮放: \(scale)")
        
        // 計算內容座標
        let contentPoint = CGPoint(
            x: (screenPoint.x - offset.width) / scale,
            y: (screenPoint.y - offset.height) / scale
        )
        
        print("📍 轉換後內容座標: \(contentPoint)")
        return contentPoint
    }
    
    /// 移動元件到指定位置
    private func moveComponentAt(id: UUID, point: CGPoint) {
        // 獲取調整後的座標（考慮縮放）
        let adjustedPoint = screenToContentCoordinate(screenPoint: point)
        
        // 更新PAD位置
        if var pad = layoutManager.pads[id] {
            pad.centerLocateX = Int32(adjustedPoint.x)
            pad.centerLocateY = Int32(adjustedPoint.y)
            layoutManager.updatePAD(pad)
        }
        
        // 如果是Pin（需要處理關聯的PAD）
        if let pin = layoutManager.pins[id] {
            // Pin的具體移動邏輯取決於您的應用需求
            // 移動關聯的PAD
            for padID in pin.padIDs {
                if var pad = layoutManager.pads[padID] {
                    pad.centerLocateX = Int32(adjustedPoint.x)
                    pad.centerLocateY = Int32(adjustedPoint.y)
                    layoutManager.updatePAD(pad)
                }
            }
        }
        
        // 記錄歷史
        layoutManager.recordHistory()
    }
    
    // MARK: - 元件操作方法
    
    /// 移動選中的元件
    private func moveSelectedComponents(translation: CGSize) {
        // 縮放調整 - 使移動距離與當前縮放比例相適應
        let adjustedTranslation = CGSize(
            width: translation.width / scale,
            height: translation.height / scale
        )
        
        // 更新所有選中元件的位置
        for componentID in layoutManager.selectedComponents {
            // 如果是PAD
            if var pad = layoutManager.pads[componentID] {
                pad.centerLocateX += Int32(adjustedTranslation.width)
                pad.centerLocateY += Int32(adjustedTranslation.height)
                layoutManager.updatePAD(pad)
            }
            
            // 如果是Pin（需要處理關聯的PAD）
            if let pin = layoutManager.pins[componentID] {
                // Pin的具體移動邏輯取決於您的應用需求
            }
        }
        
        // 記錄歷史
        layoutManager.recordHistory()
    }
    
    // MARK: - 元件檢測方法
    
    /// 檢測指定位置是否有元件 - 改進版
    private func hitTest(_ location: CGPoint) -> UUID? {
        // 轉換到內容座標系
        let adjustedLocation = screenToContentCoordinate(screenPoint: location)
        print("🔍 碰撞檢測 - 調整後位置: \(adjustedLocation)")
        
        // 優先檢查Pin (因為它們通常較小且在頂層)
        for (pinID, pin) in layoutManager.pins {
            if let position = getPinPosition(for: pin) {
                // 計算點擊位置與Pin中心的距離
                let distance = sqrt(
                    pow(position.x - adjustedLocation.x, 2) +
                    pow(position.y - adjustedLocation.y, 2)
                )
                
                print("📌 Pin \(pinID) - 距離: \(distance)")
                
                // 使用更寬鬆的檢測範圍 (原為10，增加到15)
                if distance < 15 {
                    return pinID
                }
            }
        }
        
        // 再檢查PAD (它們通常較大且在底層)
        for (padID, pad) in layoutManager.pads {
            // 獲取PAD的尺寸
            let dimension = pad.padDimensionID != nil ?
                layoutManager.padDimensions[pad.padDimensionID!] : nil
            let width = CGFloat(dimension?.width ?? 50)
            let height = CGFloat(dimension?.height ?? 30)
            
            // 擴大檢測範圍
            let expandedWidth = width + 10
            let expandedHeight = height + 10
            
            // 使用簡化的矩形碰撞檢測 (不考慮旋轉)
            let padRect = CGRect(
                x: CGFloat(pad.centerLocateX) - expandedWidth/2,
                y: CGFloat(pad.centerLocateY) - expandedHeight/2,
                width: expandedWidth,
                height: expandedHeight
            )
            
            print("🟩 PAD \(padID) - 矩形: \(padRect), 包含點: \(padRect.contains(adjustedLocation))")
            
            if padRect.contains(adjustedLocation) {
                return padID
            }
        }
        
        // 沒有找到元件
        print("❌ 未檢測到元件")
        return nil
    }
    
    /// 處理元件的點擊
    private func handleComponentTap(componentID: UUID) {
        // 根據當前工具模式處理點擊事件
        switch viewState.selectedTool {
        case .select:
            // 選擇工具模式下，切換選擇狀態
            layoutManager.toggleSelection(id: componentID)
            let isSelected = layoutManager.selectedComponents.contains(componentID)
            showFeedback(isSelected ? "已選擇元件" : "取消選擇元件")
            
        default:
            // 如果是編輯模式，則允許選擇元件
            if viewState.isEditMode {
                layoutManager.toggleSelection(id: componentID)
                let isSelected = layoutManager.selectedComponents.contains(componentID)
                showFeedback(isSelected ? "已選擇元件" : "取消選擇元件")
            }
        }
    }
    
    // MARK: - 視圖操作功能
    
    /// 觸覺反饋功能
    func performHapticFeedback(intensity: CGFloat = 0.5) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare() // 預先準備，減少延遲
        generator.impactOccurred(intensity: intensity)
    }
       
    /// 顯示操作反饋 - 優化後包含觸覺反饋
    private func showFeedback(_ message: String, withHaptic: Bool = true) {
        feedbackMessage = message
        showModeFeedback = true
        // 觸覺反饋
        if withHaptic {
            performHapticFeedback()
        }
        
        // 使用動畫顯示視覺反饋
        withAnimation(.easeInOut(duration: 0.2)) {
            showModeFeedback = true
        }
        
        // 同時更新調試文本
        updateDebugText(message)
        
        // 延遲隱藏反饋
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showModeFeedback = false
            }
        }
    }
    
    /// 輔助功能：按方向移動視圖
    private func moveView(direction: MoveDirection) {
        // 每次移動的距離
        let moveDistance: CGFloat = 50.0
        
        // 更新本地狀態和ViewState
        withAnimation(.spring()) {
            switch direction {
            case .up:
                offset.height += moveDistance
            case .down:
                offset.height -= moveDistance
            case .left:
                offset.width += moveDistance
            case .right:
                offset.width -= moveDistance
            }
            
            // 更新最後的偏移值
            lastOffset = offset
        }
        
        showFeedback("平移視圖")
    }
    
    // MARK: - 輔助方法
    
    /// 定義移動方向枚舉
    enum MoveDirection {
        case up, down, left, right
    }
    
    /// 獲取Pin的位置
    private func getPinPosition(for pin: ModelPin) -> CGPoint? {
        // 先獲取 Point? 類型的位置
        guard let point = pin.getPosition(pads: layoutManager.pads) else {
            return nil
        }
        
        // 轉換成 CGPoint 並返回
        return CGPoint(x: CGFloat(point.x), y: CGFloat(point.y))
    }
        
    // MARK: - 計算屬性
    
    /// 工具模式圖標
    private var toolModeIcon: String {
        if isDraggingComponent {
            return "arrow.up.and.down.and.arrow.left.and.right"
        } else if isDragging {
            return "hand.draw.fill"
        } else if isZooming {
            return "arrow.up.left.and.arrow.down.right.circle"
        } else if viewState.isEditMode {
            return "pencil.circle.fill"
        } else {
            switch viewState.selectedTool {
            case .select:
                return "arrow.up.left.and.down.right.magnifyingglass"
            case .pan:
                return "hand.draw.fill"
            case .zoom:
                return "minus.magnifyingglass"
            default:
                return "arrow.up.left.and.down.right.magnifyingglass"
            }
        }
    }
    
    /// 工具模式名稱
    private var toolModeName: String {
        if isDraggingComponent {
            return "移動元件中"
        } else if isDragging {
            return "平移視圖中"
        } else if isZooming {
            return "縮放視圖中"
        } else if viewState.isEditMode {
            return "編輯模式"
        } else {
            switch viewState.selectedTool {
            case .select:
                return "選擇模式"
            case .pan:
                return "平移模式"
            case .zoom:
                return "縮放模式"
            default:
                return "瀏覽模式"
            }
        }
    }
    
    /// 工具模式顏色
    private var toolModeColor: Color {
        if isDraggingComponent {
            return .orange
        } else if isDragging {
            return .green
        } else if isZooming {
            return .purple
        } else if viewState.isEditMode {
            return .orange
        } else {
            switch viewState.selectedTool {
            case .select:
                return .blue
            case .pan:
                return .green
            case .zoom:
                return .purple
            default:
                return .gray
            }
        }
    }

    
    // MARK: - 協議方法實現
    
    func zoomIn() {
        withAnimation(.spring()) {
            scale *= 1.2
            lastScale = scale
        }
        showFeedback("放大視圖")
    }
    
    func zoomOut() {
        withAnimation(.spring()) {
            scale /= 1.2
            lastScale = scale
        }
        showFeedback("縮小視圖")
    }
    
    func resetView() {
        withAnimation(.spring()) {
            scale = 1.0
            lastScale = 1.0
            offset = .zero
            lastOffset = .zero
        }
        showFeedback("重置視圖")
    }
    
    func selectComponent(id: UUID) {
        // 實現選擇邏輯
        if let _ = viewModel.pins.first(where: { $0.id == id }) {
            viewModel.selectPin(id: id)
        } else if let _ = viewModel.pads.first(where: { $0.id == id }) {
            viewModel.selectPAD(id: id)
        }
    }
    
    func showComponentDetails(id: UUID) {
        // 實現顯示詳情邏輯
        updateDebugText("顯示元件 \(id) 的詳情")
    }
}

