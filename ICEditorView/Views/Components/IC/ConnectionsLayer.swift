//
//  EnhancedConnectionView.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/2.
//

import SwiftUI

/// 增強版連線視覺組件 - 顯示Pin和PAD之間的連接
struct EnhancedConnectionView: View {
    // 基本屬性
    let from: CGPoint
    let to: CGPoint
    
    // 視覺化參數
    var lineType: ConnectionLineType = .straight
    var style: ConnectionStyle = .normal
    var animating: Bool = false
    
    // 動畫狀態
    @State private var progress: CGFloat = 1.0
    @State private var dashPhase: CGFloat = 0.0
    
    // 視圖
    var body: some View {
        ZStack {
            // 根據線型進行繪製
            switch lineType {
            case .straight:
                straightConnection
            case .curved:
                curvedConnection
            case .angled:
                angledConnection
            }
        }
        .onAppear {
            // 啟動動畫（如果需要）
            if animating {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    dashPhase = -20.0
                }
                
                // 繪製進度動畫
                withAnimation(Animation.easeInOut(duration: 1.0)) {
                    progress = 1.0
                }
            }
        }
    }
    
    // 直線連接
    private var straightConnection: some View {
        connectionPath(for: createStraightPath())
    }
    
    // 曲線連接
    private var curvedConnection: some View {
        connectionPath(for: createCurvedPath())
    }
    
    // 折線連接
    private var angledConnection: some View {
        connectionPath(for: createAngledPath())
    }
    
    // 創建直線路徑
    private func createStraightPath() -> Path {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
    }
    
    // 創建曲線路徑
    private func createCurvedPath() -> Path {
        Path { path in
            path.move(to: from)
            
            // 計算控制點
            let controlPoint1 = CGPoint(
                x: from.x + (to.x - from.x) / 2,
                y: from.y
            )
            
            let controlPoint2 = CGPoint(
                x: from.x + (to.x - from.x) / 2,
                y: to.y
            )
            
            path.addCurve(to: to, control1: controlPoint1, control2: controlPoint2)
        }
    }
    
    // 創建折線路徑
    private func createAngledPath() -> Path {
        Path { path in
            path.move(to: from)
            
            // 計算中間點
            let midX = from.x + (to.x - from.x) / 2
            
            // 第一個轉折點
            path.addLine(to: CGPoint(x: midX, y: from.y))
            
            // 第二個轉折點
            path.addLine(to: CGPoint(x: midX, y: to.y))
            
            // 終點
            path.addLine(to: to)
        }
    }
    
    // 根據路徑和樣式生成視圖
    private func connectionPath(for path: Path) -> some View {
        let trimmedPath = path.trimmedPath(from: 0, to: progress)
        
        return ZStack {
            // 背景較寬線條（陰影效果）
            if style == .highlighted || style == .selected {
                trimmedPath
                    .stroke(
                        style.shadowColor,
                        style: StrokeStyle(
                            lineWidth: style.lineWidth + 2,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .blur(radius: 2)
            }
            
            // 主線條
            trimmedPath
                .stroke(
                    style.gradient,
                    style: StrokeStyle(
                        lineWidth: style.lineWidth,
                        lineCap: .round,
                        lineJoin: .round,
                        dash: style.isDashed ? [6, 3] : [],
                        dashPhase: dashPhase
                    )
                )
                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
        }
    }
}

// MARK: - 連線樣式配置

/// 連線線型
enum ConnectionLineType {
    case straight
    case curved
    case angled
}

/// 連線樣式
struct ConnectionStyle: Equatable {
    // 預設樣式
    static let normal = ConnectionStyle(
        gradient: LinearGradient(
            gradient: Gradient(colors: [Color.blue, Color.green]),
            startPoint: .leading,
            endPoint: .trailing
        ),
        lineWidth: 1.5,
        isDashed: true,
        shadowColor: Color.clear
    )
    
    // 高亮樣式
    static let highlighted = ConnectionStyle(
        gradient: LinearGradient(
            gradient: Gradient(colors: [Color.blue, Color.purple]),
            startPoint: .leading,
            endPoint: .trailing
        ),
        lineWidth: 2.0,
        isDashed: false,
        shadowColor: Color.blue.opacity(0.5)
    )
    
    // 選中樣式
    static let selected = ConnectionStyle(
        gradient: LinearGradient(
            gradient: Gradient(colors: [Color.orange, Color.red]),
            startPoint: .leading,
            endPoint: .trailing
        ),
        lineWidth: 2.5,
        isDashed: false,
        shadowColor: Color.orange.opacity(0.6)
    )
    
    // 自定義樣式屬性
    let gradient: LinearGradient
    let lineWidth: CGFloat
    let isDashed: Bool
    let shadowColor: Color
    
    // 實現 Equatable 協議
    static func == (lhs: ConnectionStyle, rhs: ConnectionStyle) -> Bool {
        // 比較基本屬性
        return lhs.lineWidth == rhs.lineWidth &&
               lhs.isDashed == rhs.isDashed &&
               lhs.shadowColor.description == rhs.shadowColor.description
        // 注意：LinearGradient 不直接支援 Equatable，所以這裡只是簡單比較
    }
}

// MARK: - 關聯關係可視化視圖

/// 關聯關係可視化視圖 - 包含所有Pin和PAD的連線
struct RelationshipVisualizationView: View {
    // 數據模型
    @ObservedObject var layoutManager: ICLayoutManager
    
    // 視圖配置
    var connectionLineType: ConnectionLineType = .straight
    var highlightedPinID: UUID? = nil
    var highlightedPADID: UUID? = nil
    var selectedPinIDs: Set<UUID> = []
    var selectedPADIDs: Set<UUID> = []
    
    var body: some View {
        ZStack {
            // 繪製所有連線
            ForEach(Array(layoutManager.pins.keys), id: \.self) { pinID in
                // 使用 Group 確保返回的結構符合 View 協議
                Group {
                    if let pin = layoutManager.pins[pinID],
                       let pinPosition = getPinPosition(for: pin) {
                        
                        // 📝 優化: 先過濾出有效的連線，避免在 ForEach 中處理條件判斷
                        let validConnections = pin.padIDs.compactMap { padID -> (UUID, CGPoint, ConnectionStyle, Bool)? in
                            // 過濾掉不存在的 PAD
                            guard let pad = layoutManager.pads[padID] else { return nil }
                            
                            // 計算 PAD 位置
                            let padPosition = CGPoint(
                                x: CGFloat(pad.centerLocateX),
                                y: CGFloat(pad.centerLocateY)
                            )
                            
                            // 決定連線樣式
                            let style: ConnectionStyle
                            let isAnimating: Bool
                            
                            if selectedPinIDs.contains(pinID) || selectedPADIDs.contains(padID) {
                                // 選中樣式
                                style = .selected
                                isAnimating = false
                            } else if pinID == highlightedPinID || padID == highlightedPADID {
                                // 高亮樣式
                                style = .highlighted
                                isAnimating = true
                            } else {
                                // 普通樣式
                                style = .normal
                                isAnimating = false
                            }
                            
                            // 返回連線所需的所有資訊
                            return (padID, padPosition, style, isAnimating)
                        }
                        
                        // 使用過濾後的資料繪製連線
                        ForEach(validConnections, id: \.0) { padID, padPosition, style, isAnimating in
                            EnhancedConnectionView(
                                from: pinPosition,
                                to: padPosition,
                                lineType: connectionLineType,
                                style: style,
                                animating: isAnimating
                            )
                            .onTapGesture {
                                // 處理連線點擊
                                handleConnectionTap(pinID: pinID, padID: padID)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // 處理連線點擊的方法
    private func handleConnectionTap(pinID: UUID, padID: UUID) {
        // 實作點擊連線的處理邏輯
        print("連線被點擊：Pin \(pinID) 到 PAD \(padID)")
        
        // 選擇相關元件
        layoutManager.clearSelection()
        layoutManager.selectComponent(id: pinID)
        layoutManager.selectComponent(id: padID)
    }
    
    // 獲取Pin的位置
    func getPinPosition(for pin: ModelPin) -> CGPoint? {
        // 先獲取位置
        guard let point = pin.getPosition(pads: layoutManager.pads) else {
            return nil
        }
        
        // 轉換成CGPoint並返回
        return CGPoint(x: CGFloat(point.x), y: CGFloat(point.y))
    }
}

// MARK: - 集成到主視圖

/// 將增強的連線視圖集成到主視圖
extension ICLayoutViewModernized {
    // 更新後的主內容區域，包含增強的連線顯示
    func enhancedContentLayerWithConnections(geometry: GeometryProxy) -> some View {
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
            
            // 使用增強的連線視圖
            if viewState.showConnections {
                RelationshipVisualizationView(
                    layoutManager: layoutManager,
                    connectionLineType: .curved, // 可以根據用戶偏好設置
                    highlightedPinID: viewState.hoveredComponentID, // 假設添加了懸停狀態
                    selectedPinIDs: layoutManager.selectedComponents.intersection(
                        Set(layoutManager.pins.keys)
                    ),
                    selectedPADIDs: layoutManager.selectedComponents.intersection(
                        Set(layoutManager.pads.keys)
                    )
                )
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
        .scaleEffect(gestureState.scale)
        .offset(gestureState.offset)
    }
}
