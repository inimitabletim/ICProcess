//
//  ICLayoutView.swift
//  ICPinAssignmentViewer
//
//  Created by TimChi on 2025/3/26.
//  優化手勢控制與現代化界面版本

import SwiftUI
import UIKit // 用於觸覺反饋

/// IC布局主視圖
struct ICLayoutView: View {
    @ObservedObject var layoutManager: ICLayoutManager
    @StateObject private var viewState = ICLayoutViewState()
    @State private var showModeFeedback = false
    @State private var feedbackMessage = ""
    
    // 手勢狀態追踪
    @State private var isPanning = false
    @State private var isZooming = false
    @State private var isDraggingComponent = false
    @State private var dragStartLocation: CGPoint? = nil
    @State private var lastGestureLocation: CGPoint? = nil
    
    // 公司名稱與版本資訊
    private let companyName = "AIP ESD Team"
    private let appVersion = "v1.0.5"
    
    // 通過GeometryReader獲取視圖尺寸
    var body: some View {
        GeometryReader { geometry in
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
                        
                        // 內容層 - 可縮放與平移
                        contentLayer
                            .scaleEffect(viewState.scale)
                            .offset(viewState.offset)
                            // 使用智能組合手勢
                            .gesture(intelligentGestures)
                            // 添加平滑動畫
                            .animation(.interactiveSpring(), value: viewState.scale)
                            .animation(.interactiveSpring(), value: viewState.offset)
                    }
                    
                    // 右側工具面板
                    VStack {
                        Spacer()
                        rightToolPanel
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .padding(.trailing, 20)
                    
                    // 底部信息面板
                    VStack {
                        Spacer()
                        bottomInfoPanel(geometry: geometry)
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
        }
    }
    
    // MARK: - 現代化公司頂部導航欄
    
    private var companyTopBar: some View {
        HStack(spacing: 0) {
            // 左側公司標誌與名稱
            HStack(spacing: 12) {
                // 公司標誌圖標
                Image(systemName: "cpu.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.blue.opacity(0.8))
                    .cornerRadius(10)
                
                // 公司名稱與版本
                VStack(alignment: .leading, spacing: 2) {
                    Text("IC排列視覺化工具")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("\(companyName) · \(appVersion)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, 20)
            
            Spacer()
            
            // 中央操作按鈕組
            topBarButtonGroup
            
            Spacer()
            
            // 右側用戶與設置
            HStack(spacing: 15) {
                Button(action: {
                    // 幫助文檔或教學功能
                    showFeedback("開啟說明文檔")
                }) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 18))
                        .foregroundColor(.primary)
                }
                
                Button(action: {
                    // 設置功能
                    showFeedback("開啟設置選項")
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18))
                        .foregroundColor(.primary)
                }
            }
            .padding(.trailing, 20)
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
        HStack(spacing: 2) {
            // 檔案操作群組
            Group {
                TopBarButton(action: {
                    // 匯入功能
                    showFeedback("匯入檔案")
                }, icon: "square.and.arrow.down", label: "匯入")
                
                TopBarButton(action: {
                    // 匯出功能
                    showFeedback("匯出檔案")
                }, icon: "square.and.arrow.up", label: "匯出")
                
                Divider()
                    .frame(height: 24)
                    .padding(.horizontal, 8)
            }
            
            // 編輯操作群組
            Group {
                TopBarButton(action: {
                    layoutManager.undo()
                    showFeedback("復原")
                }, icon: "arrow.uturn.backward", label: "復原")
                
                TopBarButton(action: {
                    layoutManager.redo()
                    showFeedback("重做")
                }, icon: "arrow.uturn.forward", label: "重做")
                
                Divider()
                    .frame(height: 24)
                    .padding(.horizontal, 8)
            }
            
            // 視圖操作群組
            Group {
                TopBarButton(action: {
                    viewState.isEditMode.toggle()
                    showFeedback(viewState.isEditMode ? "編輯模式" : "瀏覽模式")
                }, icon: viewState.isEditMode ? "pencil.circle.fill" : "pencil.circle",
                   label: viewState.isEditMode ? "編輯中" : "編輯",
                   isActive: viewState.isEditMode)
                
                TopBarButton(action: {
                    // 切換到選擇工具
                    viewState.selectedTool = .select
                    showFeedback("選擇工具")
                }, icon: "hand.point.up.fill", label: "選擇",
                   isActive: viewState.selectedTool == .select)
                
                TopBarButton(action: {
                    // 切換到平移工具
                    viewState.selectedTool = .pan
                    showFeedback("平移工具")
                }, icon: "hand.draw.fill", label: "平移",
                   isActive: viewState.selectedTool == .pan)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(white: 0.95))
        .cornerRadius(8)
    }
    
    // 現代化頂部按鈕元件
    struct TopBarButton: View {
        let action: () -> Void
        let icon: String
        let label: String
        var isActive: Bool = false
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(isActive ? .blue : .primary)
                    
                    Text(label)
                        .font(.system(size: 10))
                        .foregroundColor(isActive ? .blue : .primary)
                }
                .frame(width: 50, height: 40)
                .background(isActive ? Color.blue.opacity(0.1) : Color.clear)
                .cornerRadius(6)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - 內容層
    
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
                    .onTapGesture {
                        // 單擊選擇PAD
                        handleComponentTap(componentID: padID)
                    }
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
                    .onTapGesture {
                        // 單擊選擇Pin
                        handleComponentTap(componentID: pinID)
                    }
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
                    withAnimation(.spring()) {
                        viewState.scale *= 1.2
                    }
                    showFeedback("放大")
                }, label: "放大")
                
                ToolbarButton(icon: "minus.magnifyingglass", action: {
                    withAnimation(.spring()) {
                        viewState.scale /= 1.2
                    }
                    showFeedback("縮小")
                }, label: "縮小")
                
                ToolbarButton(icon: "arrow.counterclockwise", action: {
                    withAnimation(.spring()) {
                        viewState.resetView()
                    }
                    showFeedback("重置視圖")
                }, label: "重置")
            }
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.8))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 2)
            
            // 方向控制按鈕
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
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.8))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 2)
            
            // 顯示選項
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
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.8))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 2)
        }
        .frame(width: 80)
        .padding(.trailing, 8)
    }
    
    // 工具欄按鈕組件
    struct ToolbarButton: View {
        let icon: String
        let action: () -> Void
        let label: String
        var isActive: Bool = false
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(isActive ? .blue : .primary)
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.5))
                        .cornerRadius(8)
                    
                    if !label.isEmpty {
                        Text(label)
                            .font(.system(size: 10))
                            .foregroundColor(isActive ? .blue : .primary)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isActive ? Color.blue.opacity(0.1) : Color.clear)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
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
            Text("比例: \(Int(viewState.scale * 100))% | 偏移: (\(Int(viewState.offset.width)), \(Int(viewState.offset.height)))")
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
    
    // MARK: - 改進的手勢處理
    
    /// 智能手勢組合 - 自動識別用戶意圖
    private var intelligentGestures: some Gesture {
        // 組合雙指縮放和拖動手勢
        let magnificationAndDrag = SimultaneousGesture(
            // 縮放手勢
            MagnificationGesture()
                .onChanged { value in
                    handleMagnificationChange(value: value)
                }
                .onEnded { _ in
                    handleMagnificationEnd()
                },
            
            // 拖動手勢
            DragGesture(minimumDistance: 3)
                .onChanged { value in
                    handleIntelligentDragChange(value: value)
                }
                .onEnded { value in
                    handleIntelligentDragEnd(value: value)
                }
        )
        
        // 點擊手勢處理
        let tapGesture = TapGesture()
            .onEnded {
                // 處理點擊事件 - 如果沒有其他進行中的手勢
                if !isPanning && !isZooming && !isDraggingComponent {
                    // 檢查點擊位置是否命中元件
                    if let componentID = hitTest(dragStartLocation ?? .zero) {
                        handleTap(componentID: componentID)
                    } else {
                        // 點擊空白區域
                        if viewState.isEditMode {
                            // 清除所有選擇
                            layoutManager.clearSelection()
                            showFeedback("已清除所有選擇")
                        }
                    }
                }
                
                // 重置手勢狀態
                resetGestureState()
            }
        
        // 組合所有手勢，設置優先級
        return magnificationAndDrag.exclusively(before: tapGesture)
    }
    
    /// 處理智能拖動變化 - 自動判斷是移動元件還是平移視圖
    private func handleIntelligentDragChange(value: DragGesture.Value) {
        // 第一次收到拖動時，記錄起始位置並判斷意圖
        if dragStartLocation == nil {
            dragStartLocation = value.startLocation
            
            // 檢查是否點擊到元件
            if let componentID = hitTest(value.startLocation) {
                if viewState.isEditMode {
                    // 編輯模式下，準備移動元件
                    isDraggingComponent = true
                    
                    // 如果元件未被選中，先選中它
                    if !layoutManager.selectedComponents.contains(componentID) {
                        layoutManager.clearSelection()
                        layoutManager.selectComponent(id: componentID)
                        showFeedback("已選擇元件")
                    }
                } else {
                    // 非編輯模式下，如果選擇了工具，則按工具處理
                    if viewState.selectedTool == .select {
                        // 選擇模式，僅選擇元件不移動
                        layoutManager.toggleSelection(id: componentID)
                        showFeedback(layoutManager.selectedComponents.contains(componentID) ? "已選擇元件" : "取消選擇元件")
                        return
                    } else {
                        // 其他模式則是平移視圖
                        isPanning = true
                    }
                }
            } else {
                // 點擊空白區域，準備平移視圖
                isPanning = true
            }
        }
        
        // 根據判斷的意圖執行操作
        if isDraggingComponent && viewState.isEditMode {
            // 1. 移動選中的元件
            moveSelectedComponents(translation: value.translation)
        } else if isPanning || viewState.selectedTool == .pan {
            // 2. 平移整個視圖
            viewState.offset = CGSize(
                width: viewState.lastOffset.width + value.translation.width,
                height: viewState.lastOffset.height + value.translation.height
            )
        }
    }
    
    /// 處理智能拖動結束
    private func handleIntelligentDragEnd(value: DragGesture.Value) {
        if isDraggingComponent {
            // 完成元件移動
            finalizeComponentMovement()
            showFeedback("元件移動完成")
        } else if isPanning {
            // 完成視圖平移
            viewState.lastOffset = viewState.offset
            
            // 只有在實際移動了一定距離時才提供反饋
            if abs(value.translation.width) > 5 || abs(value.translation.height) > 5 {
                showFeedback("平移視圖")
            }
        }
        
        // 重置手勢狀態
        resetGestureState()
    }
    
    /// 處理縮放變化 - 更簡單的邏輯
    private func handleMagnificationChange(value: MagnificationGesture.Value) {
        // 只要不是編輯模式，就允許縮放
        if !viewState.isEditMode || viewState.selectedTool == .pan {
            isZooming = true
            let newScale = viewState.lastScale * value
            // 限制縮放範圍
            viewState.scale = min(max(0.1, newScale), 5.0)
        }
    }
    
    /// 處理縮放結束
    private func handleMagnificationEnd() {
        if isZooming {
            // 更新最後的縮放值
            viewState.lastScale = viewState.scale
            showFeedback("縮放比例: \(Int(viewState.scale * 100))%")
            isZooming = false
        }
    }
    
    /// 重置所有手勢狀態
    private func resetGestureState() {
        isPanning = false
        isZooming = false
        isDraggingComponent = false
        dragStartLocation = nil
    }
    
    // MARK: - 元件操作
    
    /// 移動選中的元件
    private func moveSelectedComponents(translation: CGSize) {
        // 縮放調整 - 使移動距離與當前縮放比例相適應
        let adjustedTranslation = CGSize(
            width: translation.width / viewState.scale,
            height: translation.height / viewState.scale
        )
        
        // 更新所有選中元件的位置
        for componentID in layoutManager.selectedComponents {
            // 如果是PAD
            if var pad = layoutManager.pads[componentID] {
                pad.centerLocateX += Int32(Float(adjustedTranslation.width))
                pad.centerLocateY += Int32(adjustedTranslation.height)
                layoutManager.updatePAD(pad)
            }
            
            // 如果是Pin（需要處理關聯的PAD）
            // 注意：通常Pin的位置是由關聯的PAD決定的，這裡僅作示例
            if let pin = layoutManager.pins[componentID] {
                // Pin的具體移動邏輯取決於您的應用需求
                // 這裡我們僅處理最簡單的情況
            }
        }
    }
    
    /// 完成元件移動操作
    private func finalizeComponentMovement() {
        // 這裡可以進行移動後的清理工作
        // 例如將操作記錄到歷史記錄中以支持撤銷/重做
        // 或者檢查元件新位置的有效性等
        
        // 顯示移動結果反饋
        let count = layoutManager.selectedComponents.count
        showFeedback("已移動 \(count) 個元件")
    }
    
    /// 檢測指定位置是否有元件
    private func hitTest(_ location: CGPoint) -> UUID? {
        // 需要考慮當前縮放和偏移
        let adjustedLocation = CGPoint(
            x: (location.x - viewState.offset.width) / viewState.scale,
            y: (location.y - viewState.offset.height) / viewState.scale
        )
        
        // 先檢查Pin，因為它們通常較小且在頂層
        for (pinID, pin) in layoutManager.pins {
            if let position = getPinPosition(for: pin) {
                // 簡單的圓形碰撞檢測
                let distance = sqrt(pow(position.x - adjustedLocation.x, 2) +
                                   pow(position.y - adjustedLocation.y, 2))
                if distance < 10 {  // Pin視圖的半徑
                    return pinID
                }
            }
        }
        
        // 再檢查PAD，它們通常較大且在底層
        for (padID, pad) in layoutManager.pads {
            // 獲取PAD的尺寸
            let dimension = pad.padDimensionID != nil ?
                           layoutManager.padDimensions[pad.padDimensionID!] : nil
            let width = CGFloat(dimension?.width ?? 50)
            let height = CGFloat(dimension?.height ?? 30)
            
            // PAD中心
            let center = CGPoint(x: CGFloat(pad.centerLocateX), y: CGFloat(pad.centerLocateY))
            
            // 簡單的矩形碰撞檢測 (考慮理想情況，不考慮旋轉)
            // 實際應用中可能需要更複雜的碰撞檢測邏輯
            if abs(center.x - adjustedLocation.x) < width/2 &&
               abs(center.y - adjustedLocation.y) < height/2 {
                return padID
            }
        }
        
        // 沒有找到元件
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
    
    /// 處理元件的點擊
    private func handleTap(componentID: UUID) {
        if viewState.selectedTool == .select || !viewState.isEditMode {
            layoutManager.toggleSelection(id: componentID)
            
            // 顯示反饋
            let isSelected = layoutManager.selectedComponents.contains(componentID)
            showFeedback(isSelected ? "已選擇元件" : "取消選擇元件")
        }
    }
    
    // MARK: - 視圖操作功能
    
    /// 觸覺反饋功能
    func performHapticFeedback(intensity: CGFloat = 0.5) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred(intensity: intensity)
    }
    
    /// 輔助功能：按方向移動視圖
    private func moveView(direction: MoveDirection) {
        // 每次移動的距離
        let moveDistance: CGFloat = 50.0
        
        withAnimation(.spring()) {
            switch direction {
            case .up:
                viewState.offset.height += moveDistance
            case .down:
                viewState.offset.height -= moveDistance
            case .left:
                viewState.offset.width += moveDistance
            case .right:
                viewState.offset.width -= moveDistance
            }
        }
        
        // 更新最後的偏移值
        viewState.lastOffset = viewState.offset
        showFeedback("平移視圖")
    }
    
    /// 顯示操作反饋 - 優化後包含觸覺反饋
    private func showFeedback(_ message: String, withHaptic: Bool = true) {
        feedbackMessage = message
        
        // 觸覺反饋
        if withHaptic {
            performHapticFeedback()
        }
        
        // 使用動畫顯示視覺反饋
        withAnimation(.easeInOut(duration: 0.2)) {
            showModeFeedback = true
        }
        
        // 延遲隱藏反饋
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showModeFeedback = false
            }
        }
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
        return CGPoint(x: point.x, y: point.y)
    }
    
    // MARK: - 計算屬性
    
    /// 工具模式圖標
    private var toolModeIcon: String {
        if isDraggingComponent {
            return "arrow.up.and.down.and.arrow.left.and.right"
        } else if isPanning {
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
            default:
                return "arrow.up.left.and.down.right.magnifyingglass"
            }
        }
    }
    
    /// 工具模式名稱
    private var toolModeName: String {
        if isDraggingComponent {
            return "移動元件中"
        } else if isPanning {
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
            default:
                return "瀏覽模式"
            }
        }
    }
    
    /// 工具模式顏色
    private var toolModeColor: Color {
        if isDraggingComponent {
            return .orange
        } else if isPanning {
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
            default:
                return .gray
            }
        }
    }
}

// 支援 Point 轉 CGPoint 的擴展
extension Point {
    var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }
}
