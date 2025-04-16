//
//  ICBoundaryView.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/9.
//

import SwiftUI

/// IC 邊框視圖組件
struct ICBoundaryView: View {
    // MARK: - 屬性
    let layoutManager: ICLayoutManager
    let useFixedBoundary: Bool
    let fixedBoundarySize: CGSize
    
    // 邊框樣式設定
    private let borderColor = Color.black
    private let borderWidth: CGFloat = 2
    private let cornerRadius: CGFloat = 0 // 如果需要圓角可以調整
    private let paddingInset: CGFloat = 20 // 動態邊框的內邊距
    
    // MARK: - 計算屬性
    /// 計算動態邊框尺寸
    private var dynamicBoundaryRect: CGRect {
        // 如果沒有 PAD，返回預設尺寸
        guard !layoutManager.pads.isEmpty else {
            return CGRect(origin: .zero, size: fixedBoundarySize)
        }
        
        // 使用統一座標系統計算所有 PAD 的邊界
        var allPadBounds: [(minX: Double, minY: Double, maxX: Double, maxY: Double)] = []
        
        for pad in layoutManager.pads.values {
            // 獲取 PAD 的尺寸
            let dimension = pad.padDimensionID != nil ? layoutManager.padDimensions[pad.padDimensionID!] : nil
            let width = Double(dimension?.width ?? 50)
            let height = Double(dimension?.height ?? 30)
            
            // 計算旋轉後的邊界
            let bounds = CoordinateSystem.getRotatedRectBounds(
                center: pad.position,
                width: width,
                height: height,
                rotationDegrees: pad.rotatedAngle
            )
            
            allPadBounds.append(bounds)
        }
        
        // 計算所有 PAD 邊界的極值
        let minX = allPadBounds.map { $0.minX }.min() ?? 0
        let minY = allPadBounds.map { $0.minY }.min() ?? 0
        let maxX = allPadBounds.map { $0.maxX }.max() ?? 0
        let maxY = allPadBounds.map { $0.maxY }.max() ?? 0
        
        // 添加邊距
        let padding: Double = Double(paddingInset)
        return CGRect(
            x: minX - padding,
            y: minY - padding,
            width: maxX - minX + padding * 2,
            height: maxY - minY + padding * 2
        )
    }

    
    // MARK: - 視圖主體
    var body: some View {
        if useFixedBoundary {
            // 固定邊框 - 居中顯示
            Rectangle()
                .strokeBorder(borderColor, lineWidth: borderWidth)
                .frame(width: fixedBoundarySize.width, height: fixedBoundarySize.height)
                .position(x: fixedBoundarySize.width / 2, y: fixedBoundarySize.height / 2)
        } else {
            // 動態邊框 - 根據PAD位置調整
            let rect = dynamicBoundaryRect
            Rectangle()
                .strokeBorder(borderColor, lineWidth: borderWidth)
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
        }
    }
    
    // 輔助方法：旋轉點
    private func rotatePoint(_ point: CGPoint, around center: CGPoint, angle: Double) -> CGPoint {
        let dx = point.x - center.x
        let dy = point.y - center.y
        
        let angleInRadians = angle * .pi / 180.0
        let cosAngle = cos(angleInRadians)
        let sinAngle = sin(angleInRadians)
        
        let rotatedX = center.x + dx * CGFloat(cosAngle) - dy * CGFloat(sinAngle)
        let rotatedY = center.y + dx * CGFloat(sinAngle) + dy * CGFloat(cosAngle)
        
        return CGPoint(x: rotatedX, y: rotatedY)
    }
}
