//
//  ICLayoutViewModernized+Helpers.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/8.
//

import SwiftUI
import Combine

extension ICLayoutViewModernized {
    // MARK: - 初始化方法
    
    func initializeViewState() {
        // 初始化手勢狀態
        gestureState.scale = viewState.scale
        gestureState.lastScale = viewState.scale
        gestureState.offset = viewState.offset
        gestureState.lastOffset = viewState.lastOffset
        gestureState.minScale = 0.1
        gestureState.maxScale = 5.0
        
        // 明確確保邊框可見
        viewState.showICBoundary = true
        
        setupKeyModifierDetection()
    }
    
    /// 設置鍵盤修飾符檢測
    func setupKeyModifierDetection() {
        #if targetEnvironment(simulator)
        // 在模擬器中監聽鍵盤修飾符
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
            // 每次應用激活時重置狀態
            self.isMultiSelectMode = false
            self.gestureState.gestureModifiers.remove(.shift)
        }
        #endif
    }
    
    // MARK: - 視圖操作
    
    /// UserModeViewProtocol實現 - 保持與協議的兼容性
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
    
    // MARK: - 移動方向功能
    
    func moveView(direction: MoveDirection) {
        // 每次移動的距離 - 在iPad上增加移動距離
        let moveDistance: CGFloat = iPadMode ? 100.0 : 50.0
        
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
            
            // 同步更新視圖工具模式
            if viewState.selectedTool != ICLayoutViewState.LayoutTool.pan {
                viewState.previousTool = viewState.selectedTool
                viewState.selectedTool = ICLayoutViewState.LayoutTool.pan
            }
        }
        
        showFeedback("平移視圖", true)
        
        // 延遲恢復之前的工具模式
        if let previousTool = viewState.previousTool {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewState.selectedTool = previousTool
                    viewState.previousTool = nil
                }
            }
        }
    }
    
    // MARK: - PAD操作
    
    func movePADToPosition(padID: UUID, newPosition: CGPoint) {
        guard var pad = layoutManager.pads[padID] else { return }
        
        // 設定新位置
        pad.centerLocateX = Int32(newPosition.x)
        pad.centerLocateY = Int32(newPosition.y)
        
        // 更新PAD
        layoutManager.updatePAD(pad)
    }
    
    // MARK: - 狀態同步
    
    func syncScaleToViewState(_ newValue: CGFloat) {
        viewState.scale = newValue
        viewState.lastScale = gestureState.lastScale
    }
    
    func syncOffsetToViewState(_ newValue: CGSize) {
        viewState.offset = newValue
        viewState.lastOffset = gestureState.lastOffset
    }
    
    func syncViewStateScaleToLocal(_ newValue: CGFloat) {
        if gestureState.scale != newValue {
            gestureState.scale = newValue
            gestureState.lastScale = newValue
        }
    }
    
    func syncViewStateOffsetToLocal(_ newValue: CGSize) {
        if gestureState.offset != newValue {
            gestureState.offset = newValue
            gestureState.lastOffset = newValue
        }
    }
    
    // MARK: - 座標轉換與碰撞檢測
    
    /// 座標轉換: 螢幕座標到內容座標
    /// - Parameter screenPoint: 螢幕座標點
    /// - Returns: 對應的內容座標點
    func screenToContentCoordinate(screenPoint: CGPoint) -> CGPoint {
        // 轉換公式: (螢幕座標 - 偏移) / 縮放比例 = 內容座標
        let contentPoint = CGPoint(
            x: (screenPoint.x - gestureState.offset.width) / gestureState.scale,
            y: (screenPoint.y - gestureState.offset.height) / gestureState.scale
        )
        
        // 調試輸出 (僅在調試模式)
        if showDebugInfo {
            print("📐 座標轉換: 螢幕(\(Int(screenPoint.x)), \(Int(screenPoint.y))) → 內容(\(Int(contentPoint.x)), \(Int(contentPoint.y)))")
        }
        
        return contentPoint
    }
    
    /// 座標轉換: 內容座標到螢幕座標
    /// - Parameter contentPoint: 內容座標點
    /// - Returns: 對應的螢幕座標點
    func contentToScreenCoordinate(contentPoint: CGPoint) -> CGPoint {
        // 轉換公式: 內容座標 * 縮放比例 + 偏移 = 螢幕座標
        return CGPoint(
            x: contentPoint.x * gestureState.scale + gestureState.offset.width,
            y: contentPoint.y * gestureState.scale + gestureState.offset.height
        )
    }
    
    func hitTest(_ location: CGPoint) -> UUID? {
        // 轉換到內容座標系
        let adjustedLocation = screenToContentCoordinate(screenPoint: location)
        
        // 優先檢查Pin (因為通常較小且在頂層)
        for (pinID, pin) in layoutManager.pins {
            if let position = getPinPosition(for: pin) {
                // 計算點擊位置與Pin中心的距離
                let distance = distanceBetween(position, adjustedLocation)
                
                // 使用較寬鬆的檢測範圍以提升用戶體驗
                if distance < 15 {
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
                return padID
            }
        }
        
        // 沒有找到元件
        return nil
    }
    
    func distanceBetween(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        return sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2))
    }
    
    func pointInRotatedRect(
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
    
    // MARK: - 反饋與提示
    
    /// 顯示操作反饋提示 - 簡化版
    func showFeedback(_ message: String, _ withHaptic: Bool) {
        feedbackMessage = message
        
        // 視覺反饋
        withAnimation(.easeInOut(duration: 0.3)) {
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
    }
    
    func showImportAlert(success: Bool, message: String) {
        importAlertIsSuccess = success
        importAlertMessage = message
        showingImportAlert = true
    }
    
    // MARK: - 數據處理
    
    func updateLayoutManagerFromViewModel() {
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
    
    func getPinPosition(for pin: ModelPin) -> CGPoint? {
        // 如果Pin關聯了PAD，位置就是PAD的中心點
        if let padID = pin.padIDs.first, let pad = layoutManager.pads[padID] {
            return CGPoint(x: CGFloat(pad.centerLocateX), y: CGFloat(pad.centerLocateY))
        }
        return nil
    }
}
