//
//  ICLayoutViewOptimized.swift
//  ICEditorView
//
//  Created by TimChi on 2025/3/31.
//

import SwiftUI
import Combine


/// 優化版的IC排列視覺化視圖
struct ICLayoutViewOptimized: View, UserModeViewProtocol {
    // MARK: - 數據模型
    @ObservedObject var layoutManager: ICLayoutManager
    @ObservedObject var viewModel: ICLayoutViewModel
    @ObservedObject var viewState: ICLayoutViewState
    
    // MARK: - 手勢狀態
    @StateObject private var gestureState = GestureState()
    
    // MARK: - 界面狀態
    @State private var showModeFeedback = false
    @State private var feedbackMessage = ""
    @State private var isDirectionPanelExpanded: Bool = false
    @State private var isViewOptionsPanelExpanded: Bool = false
    
    // MARK: - CSV匯入狀態
    @State private var isImportingCSV = false
    @State private var showingImportAlert = false
    @State private var importAlertMessage = ""
    @State private var importAlertIsSuccess = false
    
    // MARK: - 調試狀態 (如果 viewState 沒有此屬性)
    @State private var showDebugInfo: Bool = false
    
    // MARK: - 多選模式
    @State private var isMultiSelectMode: Bool = false

    // MARK: - 主視圖
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    // 頂部導航欄
                    companyTopBar
                        .frame(height: 60)
                    
                    ZStack {
                        // 背景
                        Color(white: 0.95)
                            .ignoresSafeArea()
                        
                        // 主內容區域
                        ZStack {
                            // 網格背景 (如果啟用)
                            if viewState.showGrid {
                                GridBackgroundView(viewSize: geometry.size)
                            }
                            
                            // 內容層 - 優化後的手勢處理
                            contentLayerWithSmartGestures(geometry: geometry)
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
                        
                        // 調試面板 (可選)
                        if showDebugInfo {
                            VStack {
                                GestureDiagnosticsView(gestureState: gestureState)
                                    .padding(10)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        }
                    }
                }
                
//                // 右側工具面板
//                VStack {
//                    rightToolPanel
//                        .padding(.top, 75)
//                    Spacer()
//                }
//                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
//                
//                // 浮動控制區
//                VStack {
//                    Spacer()
//                    HStack {
//                        Spacer()
//                        floatingControlArea
//                    }
//                }
                
                // 底部信息面板
                VStack {
                    Spacer()
                    bottomInfoPanel(geometry: geometry)
                }
            }
            .edgesIgnoringSafeArea(.bottom)
            .onAppear {
                // 初始化視圖狀態
                initializeViewState()
                
                // 輸出初始化信息
                print("📱 視圖已初始化: 模式=\(viewState.selectedTool), 縮放=\(viewState.scale)")
                
                // 設置鍵盤修飾符檢測
                setupKeyModifierDetection()
            }
            // 同步狀態 - 使用 onChange API
            .onChange(of: gestureState.scale) { _, newValue in
                syncScaleToViewState(newValue)
            }
            .onChange(of: gestureState.offset) { _, newValue in
                syncOffsetToViewState(newValue)
            }
            .onChange(of: viewState.scale) { _, newValue in
                syncViewStateScaleToLocal(newValue)
            }
            .onChange(of: viewState.offset) { _, newValue in
                syncViewStateOffsetToLocal(newValue)
            }
            // 當工具模式改變時，重置狀態
            .onChange(of: viewState.selectedTool) { _, _ in
                gestureState.resetGestureState()
            }
            .onChange(of: viewState.isEditMode) { _, _ in
                gestureState.resetGestureState()
            }
        }
    }
    
    // MARK: - 視圖元件
    
    /// 頂部導航欄
    private var companyTopBar: some View {
        HStack(spacing: 0) {
            // 操作按鈕組
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
    
    /// 頂部按鈕組
    private var topBarButtonGroup: some View {
        HStack(spacing: 0) {
            // 文件操作區域
            ToolGroup(title: "文件") {
                ToolButton(icon: "square.and.arrow.down", label: "匯入") {
                    // 📝 觸發文件選擇器
                    isImportingCSV = true
                }
                .fileImporter(
                    isPresented: $isImportingCSV,
                    allowedContentTypes: [.commaSeparatedText], // CSV 檔案類型
                    allowsMultipleSelection: false
                ) { result in
                    // 處理檔案選擇結果
                    handleCSVImport(result: result)
                }
                .alert(isPresented: $showingImportAlert) {
                    Alert(
                        title: Text(importAlertIsSuccess ? "匯入成功" : "匯入失敗"),
                        message: Text(importAlertMessage),
                        dismissButton: .default(Text("確定"))
                    )
                }
                
                ToolButton(icon: "square.and.arrow.up", label: "匯出") {
                    // 實際匯出功能
                    showFeedback("匯出功能未實現", true)
                }
            }
            
            // 編輯操作區域
            ToolGroup(title: "編輯") {
                ToolButton(icon: "arrow.uturn.backward", label: "復原") {
                    layoutManager.undo()
                    showFeedback("復原操作", true)
                }
                
                ToolButton(icon: "arrow.uturn.forward", label: "重做") {
                    layoutManager.redo()
                    showFeedback("重做操作", true)
                }
                
                // 添加多選模式按鈕
                ToolButton(
                    icon: isMultiSelectMode ? "checkmark.circle.fill" : "checkmark.circle",
                    label: isMultiSelectMode ? "多選中" : "多選",
                    isActive: isMultiSelectMode
                ) {
                    isMultiSelectMode.toggle()
                    // 更新手勢修飾符狀態
                    if isMultiSelectMode {
                        gestureState.gestureModifiers.insert(.shift)
                    } else {
                        gestureState.gestureModifiers.remove(.shift)
                    }
                    showFeedback(isMultiSelectMode ? "多選模式已開啟" : "多選模式已關閉", true)
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
                    showFeedback(viewState.isEditMode ? "編輯模式" : "瀏覽模式", true)
                }
                
                ToolButton(
                    icon: "hand.point.up.fill",
                    label: "選擇",
                    isActive: viewState.selectedTool == .select
                ) {
                    viewState.selectedTool = .select
                    showFeedback("選擇工具", true)
                }
                
                ToolButton(
                    icon: "hand.draw.fill",
                    label: "平移",
                    isActive: viewState.selectedTool == .pan
                ) {
                    viewState.selectedTool = .pan
                    showFeedback("平移工具", true)
                }
                
                ToolButton(
                    icon: "plus.magnifyingglass",
                    label: "縮放",
                    isActive: viewState.selectedTool == .zoom
                ) {
                    viewState.selectedTool = .zoom
                    showFeedback("縮放工具", true)
                }
            }
        }
    }
    
    /// 核心內容層 - 處理所有手勢
    private func contentLayerWithSmartGestures(geometry: GeometryProxy) -> some View {
        let content = ZStack {
            // 背景網格（如果啟用）
            if viewState.showGrid {
                GridBackgroundModernized()
                    .opacity(0.15)
                    .zIndex(-20) // 確保在最底層
            }
                        
            // 繪製 PAD（原有代碼）
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
            
            // 繪製 Pin（原有代碼）
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
        .scaleEffect(gestureState.scale)
        .offset(gestureState.offset)
        
        // 改進的手勢處理邏輯（保持原有代碼）
        return content
        
        // 添加所有手勢處理
        .contentShape(Rectangle()) // 確保整個區域可接收點擊
        .onTapGesture { location in
            // 紀錄點擊位置
            gestureState.lastCursorX = location.x
            gestureState.lastCursorY = location.y
            
            // 檢測點擊位置是否有元件
            if let componentID = hitTest(location) {
                // 多選模式處理 (按住Shift鍵或啟用多選模式)
                if gestureState.gestureModifiers.contains(.shift) || isMultiSelectMode {
                    // 切換選擇狀態 (已選擇則取消，未選擇則添加)
                    if layoutManager.selectedComponents.contains(componentID) {
                        layoutManager.deselectComponent(id: componentID)
                    } else {
                        layoutManager.selectComponent(id: componentID)
                    }
                    showFeedback("批量選擇: \(layoutManager.selectedComponents.count)個元件", true)
                } else {
                    // 正常選擇 (清除其他選擇)
                    layoutManager.clearSelection()
                    layoutManager.selectComponent(id: componentID)
                    showFeedback("已選擇元件", true)
                }
                print("👆 點擊選中: \(componentID)")
            } else {
                // 點擊空白處清除選擇
                layoutManager.clearSelection()
                print("👆 清除選擇")
                showFeedback("清除選擇", false)
            }
        }
        // 2. 拖動手勢 - 處理平移畫面和拖動元件
        .gesture(
            DragGesture(minimumDistance: 2) // 降低最小拖動距離，使其更靈敏
                .onChanged { value in
                    // 保存滑鼠/觸控位置
                    gestureState.lastCursorX = value.location.x
                    gestureState.lastCursorY = value.location.y
                    
                    // 在編輯模式下，檢查是否在元件上拖動
                    if viewState.isEditMode && !gestureState.isDragging && !gestureState.isPanning {
                        // 檢查起始點是否在元件上
                        if let componentID = hitTest(value.startLocation) {
                            // 開始拖動元件
                            gestureState.isDragging = true
                            gestureState.draggedComponentID = componentID
                            
                            // 處理批量拖動 (如果啟用多選模式且元件已被選中)
                            if (gestureState.gestureModifiers.contains(.shift) ||
                                isMultiSelectMode ||
                                layoutManager.selectedComponents.count > 1) &&
                                layoutManager.selectedComponents.contains(componentID) {
                                // 使用現有選擇進行批量拖動
                                print("🎯 批量拖動元件: \(layoutManager.selectedComponents.count)個")
                            } else {
                                // 單個元件拖動，先選中
                                if !layoutManager.selectedComponents.contains(componentID) {
                                    layoutManager.clearSelection()
                                    layoutManager.selectComponent(id: componentID)
                                }
                                print("🎯 拖動單個元件: \(componentID)")
                            }
                            showFeedback("拖動元件", false)
                            
                            // 更新工具模式顯示
                            if viewState.selectedTool != .select {
                                viewState.previousTool = viewState.selectedTool
                                viewState.selectedTool = .select
                            }
                            return // 避免同時執行平移
                        }
                    }
                    
                    // 如果已經在拖動元件，執行元件移動
                    if gestureState.isDragging {
                        // 批量拖動所有選中的元件
                        if layoutManager.selectedComponents.count > 1 {
                            // 計算縮放調整後的移動距離
                            let adjustedTranslation = CGSize(
                                width: value.translation.width / gestureState.scale,
                                height: value.translation.height / gestureState.scale
                            )
                            
                            // 移動所有選中的元件
                            for componentID in layoutManager.selectedComponents {
                                moveSingleComponent(componentID: componentID, translation: adjustedTranslation)
                            }
                        }
                        // 或者移動單個元件
                        else if let componentID = gestureState.draggedComponentID {
                            moveComponent(componentID: componentID, translation: value.translation)
                        }
                        return // 避免同時執行平移
                    }
                    
                    // 執行畫面平移 (無條件限制)
                    if !gestureState.isPanning {
                        gestureState.isPanning = true
                        print("📍 平移開始")
                        showFeedback("平移模式", false)
                        
                        // 更新工具模式顯示
                        if viewState.selectedTool != .pan {
                            viewState.previousTool = viewState.selectedTool
                            viewState.selectedTool = .pan
                        }
                    }
                    
                    // 執行平移，使用動畫讓移動更流暢
                    withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7)) {
                        gestureState.offset = CGSize(
                            width: gestureState.lastOffset.width + value.translation.width,
                            height: gestureState.lastOffset.height + value.translation.height
                        )
                    }
                }
                .onEnded { value in
                    // 處理拖動結束
                    if gestureState.isPanning {
                        // 平移結束，保存最終位置
                        gestureState.lastOffset = gestureState.offset
                        gestureState.isPanning = false
                        
                        // 提供反饋
                        let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                        if distance > 5 {
                            showFeedback("平移完成", true)
                        }
                    }
                    
                    if gestureState.isDragging {
                        // 元件拖動結束
                        showFeedback("移動元件完成", true)
                        
                        // 記錄操作歷史
                        layoutManager.recordHistory()
                    }
                    
                    // 重置拖動狀態
                    gestureState.isDragging = false
                    gestureState.draggedComponentID = nil
                    
                    // 自動切換回原工具模式
                    if let previousTool = viewState.previousTool {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            viewState.selectedTool = previousTool
                            viewState.previousTool = nil
                        }
                    }
                }
            )
            // 3. 縮放功能 - 支援iPad捏合與模擬器操作
            .gesture(
                MagnificationGesture(minimumScaleDelta: 0.01)
                    .onChanged { value in
                        print("🔍 縮放手勢偵測: \(value)")
                        
                        // 啟用縮放狀態
                        gestureState.isZooming = true
                        
                        // 計算新的縮放值
                        let newScale = gestureState.lastScale * value
                        
                        // 應用縮放，保持在合理範圍內
                        withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.8)) {
                            gestureState.scale = min(max(0.2, newScale), 5.0)
                        }
                        
                        // 更新工具模式顯示
                        if viewState.selectedTool != .zoom {
                            viewState.previousTool = viewState.selectedTool
                            viewState.selectedTool = .zoom
                            showFeedback("縮放模式", false)
                        }
                        
                        print("📏 縮放中: \(gestureState.scale)")
                    }
                    .onEnded { _ in
                        // 縮放結束，保存最終縮放值
                        gestureState.lastScale = gestureState.scale
                        gestureState.isZooming = false
                        showFeedback("縮放: \(Int(gestureState.scale * 100))%", true)
                        
                        // 自動切換回原工具模式
                        if let previousTool = viewState.previousTool,
                           viewState.selectedTool == .zoom {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                viewState.selectedTool = previousTool
                                viewState.previousTool = nil
                            }
                        }
                    }
            )
            // 4. 追蹤滑鼠/觸控位置
            .onHover { isHovering in
                gestureState.isHovering = isHovering
            }
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
            Text("比例: \(Int(gestureState.scale * 100))% | 偏移: (\(Int(gestureState.offset.width)), \(Int(gestureState.offset.height)))")
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
    
    /// 模式指示器
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
    
    // MARK: - 功能方法
    
    /// 初始化視圖狀態
    private func initializeViewState() {
        // 初始化手勢狀態
        gestureState.scale = viewState.scale
        gestureState.lastScale = viewState.scale
        gestureState.offset = viewState.offset
        gestureState.lastOffset = viewState.lastOffset
        gestureState.minScale = 0.1
        gestureState.maxScale = 5.0
    }
    
    /// 設置鍵盤修飾符檢測
    private func setupKeyModifierDetection() {
        #if targetEnvironment(simulator)
        // 在模擬器中可以監聽鍵盤修飾符，但需要根據實際環境調整
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
            // 每次應用激活時重置狀態
            self.isMultiSelectMode = false
            self.gestureState.gestureModifiers.remove(.shift)
        }
        #endif
    }
    
    /// 檢測指定位置是否有元件 (碰撞檢測)
    private func hitTest(_ location: CGPoint) -> UUID? {
        // 轉換到內容座標系
        let adjustedLocation = screenToContentCoordinate(screenPoint: location)
        
        // 🔍 輸出調試信息
        print("碰撞檢測: 螢幕位置=\(location), 內容位置=\(adjustedLocation)")
        
        // 優先檢查Pin (因為通常較小且在頂層)
        for (pinID, pin) in layoutManager.pins {
            if let position = getPinPosition(for: pin) {
                // 計算點擊位置與Pin中心的距離
                let distance = distanceBetween(position, adjustedLocation)
                
                // 🔍 Pin檢測調試
                if distance < 30 {
                    print("接近Pin \(pinID): 距離=\(distance)")
                }
                
                // 使用較寬鬆的檢測範圍以提升用戶體驗
                if distance < 15 {
                    print("✅ 點擊到Pin: \(pinID)")
                    return pinID
                }
            }
        }
        
        // 再檢查PAD (因為通常較大且在底層)
        for (padID, pad) in layoutManager.pads {
            // 獲取PAD的尺寸
            let dimension = pad.padDimensionID != nil ?
                layoutManager.padDimensions[pad.padDimensionID!] : nil
            let width = CGFloat(dimension?.width ?? 50)
            let height = CGFloat(dimension?.height ?? 30)
            
            // 擴大檢測範圍
            let expandedWidth = width + 10
            let expandedHeight = height + 10
            
            // 考慮PAD的旋轉角度
            let inRect = pointInRotatedRect(
                point: adjustedLocation,
                rectCenter: CGPoint(x: CGFloat(pad.centerLocateX), y: CGFloat(pad.centerLocateY)),
                width: expandedWidth,
                height: expandedHeight,
                rotation: .degrees(pad.rotatedAngle)
            )
            
            if inRect {
                print("✅ 點擊到PAD: \(padID)")
                return padID
            }
        }
        
        // 沒有找到元件
        return nil
    }
    
    /// 處理元件選擇
    private func handleComponentSelection(componentID: UUID, isSelected: Bool) {
        if isSelected {
            // 判斷是否為多選模式 (按住Shift鍵或啟用多選模式)
            if gestureState.gestureModifiers.contains(.shift) || isMultiSelectMode {
                // 添加到已有選擇中
                layoutManager.selectComponent(id: componentID)
            } else {
                // 清除之前的選擇，只選擇當前元件
                layoutManager.clearSelection()
                layoutManager.selectComponent(id: componentID)
            }
        } else {
            // 如果已經選中，則取消選擇
            layoutManager.deselectComponent(id: componentID)
        }
        
        // 反饋
        showFeedback(isSelected ? "已選擇元件" : "取消選擇元件", true)
    }
    
    /// 移動元件
    private func moveComponent(componentID: UUID, translation: CGSize) {
        // 🔍 調試
        print("移動元件: ID=\(componentID), 移動距離=\(translation)")
        
        // 縮放調整 - 使移動距離與當前縮放比例相適應
        let adjustedTranslation = CGSize(
            width: translation.width / gestureState.scale,
            height: translation.height / gestureState.scale
        )
        
        // 如果選中了多個元件
        if layoutManager.selectedComponents.contains(componentID) && layoutManager.selectedComponents.count > 1 {
            // 移動所有選中的元件
            for selectedID in layoutManager.selectedComponents {
                moveSingleComponent(componentID: selectedID, translation: adjustedTranslation)
            }
        } else {
            // 只移動當前元件
            moveSingleComponent(componentID: componentID, translation: adjustedTranslation)
        }
    }
    
    /// 移動單個元件
    private func moveSingleComponent(componentID: UUID, translation: CGSize) {
        // 如果是PAD
        if var pad = layoutManager.pads[componentID] {
            pad.centerLocateX += Int32(translation.width)
            pad.centerLocateY += Int32(translation.height)
            layoutManager.updatePAD(pad)
        }
        
        // 如果是Pin（需要處理關聯的PAD）
        if let pin = layoutManager.pins[componentID] {
            // 移動關聯的PAD
            for padID in pin.padIDs {
                if var pad = layoutManager.pads[padID] {
                    pad.centerLocateX += Int32(translation.width)
                    pad.centerLocateY += Int32(translation.height)
                    layoutManager.updatePAD(pad)
                }
            }
        }
    }
    
    /// 顯示操作反饋 (包含視覺與觸覺反饋)
    private func showFeedback(_ message: String, _ withHaptic: Bool) {
        feedbackMessage = message
        
        // 視覺反饋
        withAnimation(.easeInOut(duration: 0.2)) {
            showModeFeedback = true
        }
        
        // 觸覺反饋
        if withHaptic {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare() // 預先準備，減少延遲
            generator.impactOccurred()
        }
        
        // 延遲隱藏反饋
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showModeFeedback = false
            }
        }
        
        // 調試輸出
        print("📢 反饋: \(message)")
    }
    
    /// 按方向移動視圖
    private func moveView(direction: MoveDirection) {
        // 每次移動的距離
        let moveDistance: CGFloat = 50.0
        
        // 更新狀態
        withAnimation(.spring()) {
            switch direction {
            case .up:
                gestureState.offset.height += moveDistance
            case .down:
                gestureState.offset.height -= moveDistance
            case .left:
                gestureState.offset.width += moveDistance
            case .right:
                gestureState.offset.width -= moveDistance
            }
            
            // 更新最後的偏移值
            gestureState.lastOffset = gestureState.offset
        }
        
        showFeedback("平移視圖", true)
    }
    
    /// 匯入CSV數據
    private func handleCSVImport(result: Result<[URL], Error>) {
        do {
            // 獲取選擇的檔案URL
            let selectedFiles = try result.get()
            
            // 確保選擇了檔案
            guard let selectedFile = selectedFiles.first else {
                showImportAlert(success: false, message: "未選擇檔案")
                return
            }
            
            // 📝 取得檔案存取權限
            if selectedFile.startAccessingSecurityScopedResource() {
                defer { selectedFile.stopAccessingSecurityScopedResource() }
                
                // 使用匯入功能處理檔案
                let importResult = viewModel.loadFromCSV(url: selectedFile)
                
                // 如果成功，更新layoutManager中的數據
                if importResult.success {
                    // 同步更新layoutManager數據
                    updateLayoutManagerFromViewModel()
                    
                    // 重置視圖
                    withAnimation(.spring()) {
                        viewState.resetView()
                        resetView()
                    }
                }
                
                // 顯示結果提示
                showImportAlert(success: importResult.success, message: importResult.message)
                showFeedback(importResult.success ? "匯入成功" : "匯入失敗", true)
            } else {
                showImportAlert(success: false, message: "無法存取選擇的檔案")
            }
        } catch {
            showImportAlert(success: false, message: "檔案選擇錯誤: \(error.localizedDescription)")
        }
    }
    
    /// 顯示匯入結果提示
    private func showImportAlert(success: Bool, message: String) {
        importAlertIsSuccess = success
        importAlertMessage = message
        showingImportAlert = true
    }
    
    /// 從ViewModel更新LayoutManager數據
    private func updateLayoutManagerFromViewModel() {
        // 將ViewModel中的數據轉換為LayoutManager需要的格式
        var pinDict: [UUID: ModelPin] = [:]
        var padDict: [UUID: ModelPAD] = [:]
        
        // 轉換Pin數據
        for pin in viewModel.pins {
            pinDict[pin.id] = pin
        }
        
        // 轉換PAD數據
        for pad in viewModel.pads {
            padDict[pad.id] = pad
        }
        
        // 更新LayoutManager數據
        layoutManager.pins = pinDict
        layoutManager.pads = padDict
        layoutManager.padDimensions = viewModel.padDimensions
        
        // 記錄歷史
        layoutManager.recordHistory()
    }
    
    /// 獲取Pin的位置
    private func getPinPosition(for pin: ModelPin) -> CGPoint? {
        // 先獲取位置
        guard let point = pin.getPosition(pads: layoutManager.pads) else {
            return nil
        }
        
        // 轉換成CGPoint並返回
        return CGPoint(x: CGFloat(point.x), y: CGFloat(point.y))
    }
    
    // MARK: - 狀態同步方法
    
    /// 同步縮放狀態到ViewState
    private func syncScaleToViewState(_ newValue: CGFloat) {
        viewState.scale = newValue
        viewState.lastScale = gestureState.lastScale
    }
    
    /// 同步偏移狀態到ViewState
    private func syncOffsetToViewState(_ newValue: CGSize) {
        viewState.offset = newValue
        viewState.lastOffset = gestureState.lastOffset
    }
    
    /// 同步ViewState縮放狀態到本地狀態
    private func syncViewStateScaleToLocal(_ newValue: CGFloat) {
        if gestureState.scale != newValue {
            gestureState.scale = newValue
            gestureState.lastScale = newValue
        }
    }
    
    /// 同步ViewState偏移狀態到本地狀態
    private func syncViewStateOffsetToLocal(_ newValue: CGSize) {
        if gestureState.offset != newValue {
            gestureState.offset = newValue
            gestureState.lastOffset = newValue
        }
    }
    
    // MARK: - 實用工具方法
    
    /// 轉換螢幕座標到內容座標（考慮縮放和偏移）
    private func screenToContentCoordinate(screenPoint: CGPoint) -> CGPoint {
        return CGPoint(
            x: (screenPoint.x - gestureState.offset.width) / gestureState.scale,
            y: (screenPoint.y - gestureState.offset.height) / gestureState.scale
        )
    }
    
    /// 計算兩點之間的距離
    private func distanceBetween(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        return sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2))
    }
    
    /// 檢查點是否在旋轉後的矩形內
    private func pointInRotatedRect(
        point: CGPoint,
        rectCenter: CGPoint,
        width: CGFloat,
        height: CGFloat,
        rotation: Angle
    ) -> Bool {
        // 將點轉換到以矩形中心為原點的座標系
        let dx = point.x - rectCenter.x
        let dy = point.y - rectCenter.y
        
        // 反向旋轉點，使矩形恢復水平
        let cosAngle = cos(-rotation.radians)
        let sinAngle = sin(-rotation.radians)
        
        let rotatedX = dx * cosAngle - dy * sinAngle
        let rotatedY = dx * sinAngle + dy * cosAngle
        
        // 檢查點是否在矩形內
        return abs(rotatedX) <= width / 2 && abs(rotatedY) <= height / 2
    }
    
    // MARK: - 計算屬性
    
    /// 工具模式圖標
    private var toolModeIcon: String {
        if gestureState.isDragging {
            return "arrow.up.and.down.and.arrow.left.and.right"
        } else if gestureState.isZooming {
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
        if gestureState.isDragging {
            return "移動元件中"
        } else if gestureState.isZooming {
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
        if gestureState.isDragging {
            return .orange
        } else if gestureState.isZooming {
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
    
    // MARK: - 移動方向枚舉
    enum MoveDirection {
        case up, down, left, right
    }
    
    // MARK: - UserModeViewProtocol實現
    
    func zoomIn() {
        withAnimation(.spring()) {
            gestureState.scale *= 1.2
            gestureState.lastScale = gestureState.scale
        }
        showFeedback("放大視圖", true)
    }
    
    func zoomOut() {
        withAnimation(.spring()) {
            gestureState.scale /= 1.2
            gestureState.lastScale = gestureState.scale
        }
        showFeedback("縮小視圖", true)
    }
    
    func resetView() {
        withAnimation(.spring()) {
            gestureState.resetView()
        }
        showFeedback("重置視圖", true)
    }
    
    func selectComponent(id: UUID) {
        layoutManager.selectComponent(id: id)
    }
    
    func showComponentDetails(id: UUID) {
        // 實現顯示詳情邏輯
        showFeedback("顯示元件詳情: \(id)", true)
    }
}

// MARK: - 輔助UI元件

/// 浮動控制面板
struct FloatingControlPanel<Content: View>: View {
    @Binding var isExpanded: Bool
    let icon: String
    let label: String
    let content: Content
    
    init(isExpanded: Binding<Bool>, icon: String, label: String, @ViewBuilder content: () -> Content) {
        self._isExpanded = isExpanded
        self.icon = icon
        self.label = label
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 內容區域 - 只在展開時顯示
            if isExpanded {
                content
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.9))
                            .shadow(color: Color.black.opacity(0.15), radius: 4, y: 2)
                    )
                    .transition(.scale.combined(with: .opacity))
            }
            
            // 展開/收起按鈕
            Button(action: {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                    
                    Text(label)
                        .font(.system(size: 12))
                        .lineLimit(1)
                    
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .font(.system(size: 10))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: Color.black.opacity(0.15), radius: 2, y: 1)
                )
                .foregroundColor(.primary)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 6)
        }
    }
}

/// 工具分組元件
struct ToolGroup<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 2) {
            // 分組標題
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .padding(.top, 4)
            
            // 工具按鈕行
            HStack(spacing: 0) {
                content
            }
        }
        .padding(.horizontal, 8)
        // 使用漸變分隔線
        .background(
            Rectangle()
                .fill(Color.clear)
                .overlay(
                    HStack {
                        Spacer()
                        Rectangle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [Color.gray.opacity(0.0), Color.gray.opacity(0.2), Color.gray.opacity(0.0)]),
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                            .frame(width: 1)
                    }
                )
        )
    }
}

/// 工具按鈕元件
struct ToolButton: View {
    let icon: String
    let label: String
    var isActive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isActive ? .medium : .regular))
                    .foregroundColor(isActive ? .blue : .primary)
                
                Text(label)
                    .font(.system(size: 9))
                    .foregroundColor(isActive ? .blue : .secondary)
            }
            .frame(width: 44, height: 40)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isActive ? Color.blue.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isActive ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

