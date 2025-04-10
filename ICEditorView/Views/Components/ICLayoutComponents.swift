//
//  ICLayoutComponents.swift
//  ICPinAssignmentViewer
//
//  Created by TimChi on 2025/3/26.
//

import SwiftUI

// MARK: - 視覺元件樣式

/// 顏色主題
struct ICColors {
    static let background = Color(white: 0.95)
    static let grid = Color.gray.opacity(0.3)
    static let pin = Color.blue
    static let pinSelected = Color.yellow
    static let pad = Color.green.opacity(0.6)
    static let padSelected = Color.orange.opacity(0.7)
    static let text = Color.black
    static let connection = Color.red.opacity(0.7)
}

// MARK: - 基本視覺元件

/// Pin視圖元件 - 支援不同大小設置
struct PinView: View {
    let pin: ModelPin
    let position: CGPoint
    var isSelected: Bool = false
    var showLabel: Bool = true
    var padSize: CGFloat = 10
    
    var body: some View {
        ZStack {
            // Pin圓點
            Circle()
                .fill(isSelected ? Color.orange : Color.blue)
                .frame(width: padSize, height: padSize)
                .position(position)
            
            // 外圈高亮(選中時)
            if isSelected {
                Circle()
                    .stroke(Color.orange, lineWidth: 2)
                    .frame(width: padSize + 4, height: padSize + 4)
                    .position(position)
            }
            
            // Pin標籤
            if showLabel {
                Text("Pin-\(pin.pinIndex)")
                    .font(.system(size: padSize > 10 ? 10 : 8))
                    .foregroundColor(.primary)
                    .background(Color.white.opacity(0.7))
                    .cornerRadius(3)
                    .offset(y: padSize + 8)
                    .position(position)
            }
        }
    }
}

/// PAD視覺組件
struct PADView: View {
    let pad: ModelPAD
    let dimension: ModelPADDimension?
    let isSelected: Bool
    let showLabel: Bool
    
    var body: some View {
        let width = CGFloat(dimension?.width ?? 50)
        let height = CGFloat(dimension?.height ?? 30)
        
        ZStack {
            // PAD矩形
            Rectangle()
                .fill(isSelected ? ICColors.padSelected : ICColors.pad)
                .frame(width: width, height: height)
                .position(CGPoint(x: CGFloat(pad.centerLocateX), y: CGFloat(pad.centerLocateY)))
                .rotationEffect(.degrees(pad.rotatedAngle))
            
            // PAD名稱 (可選顯示)
            if showLabel {
                Text(pad.name)
                    .font(.system(size: 10))
                    .foregroundColor(ICColors.text)
                    .background(Color.white.opacity(0.7))
                    .position(CGPoint(x: CGFloat(pad.centerLocateX), y: CGFloat(pad.centerLocateY)))
            }
        }
    }
}

/// 連線視覺組件 - 顯示Pin和PAD之間的連接
struct ConnectionView: View {
    let from: CGPoint
    let to: CGPoint
    
    var body: some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
        .stroke(ICColors.connection, lineWidth: 1.5)
    }
}

/// 網格背景視覺組件 - 優化版
struct GridBackgroundView: View {
    let gridSize: CGFloat
    let viewSize: CGSize
    
    init(gridSize: CGFloat = 20, viewSize: CGSize) {
        self.gridSize = gridSize
        self.viewSize = viewSize
    }
    
    var body: some View {
        Canvas { context, size in
            // 繪製水平線
            for y in stride(from: 0, to: viewSize.height, by: gridSize) {
                let path = Path { p in
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: viewSize.width, y: y))
                }
                context.stroke(path, with: .color(ICColors.grid), lineWidth: 0.5)
            }
            
            // 繪製垂直線
            for x in stride(from: 0, to: viewSize.width, by: gridSize) {
                let path = Path { p in
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x, y: viewSize.height))
                }
                context.stroke(path, with: .color(ICColors.grid), lineWidth: 0.5)
            }
        }
        .frame(width: viewSize.width, height: viewSize.height)
        .allowsHitTesting(false) // 讓下層的元素可以接收手勢
    }
}
