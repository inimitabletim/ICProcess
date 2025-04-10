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
        
        // 找出所有 PAD 的極值座標
        var minX: CGFloat = .infinity
        var minY: CGFloat = .infinity
        var maxX: CGFloat = -.infinity
        var maxY: CGFloat = -.infinity
        
        // 考慮旋轉角度的PAD邊界計算
        for pad in layoutManager.pads.values {
            // 取得PAD尺寸資訊
            let padWidth: CGFloat
            let padHeight: CGFloat
            
            if let dimensionID = pad.padDimensionID, let dimension = layoutManager.padDimensions[dimensionID] {
                padWidth = CGFloat(dimension.width)
                padHeight = CGFloat(dimension.height)
            } else {
                padWidth = 50
                padHeight = 30
            }
            
            // 計算PAD四個角的位置(考慮旋轉)
            let center = CGPoint(x: CGFloat(pad.centerLocateX), y: CGFloat(pad.centerLocateY))
            let halfWidth = padWidth / 2
            let halfHeight = padHeight / 2
            
            // 計算四個角落的點
            let topLeft = CGPoint(x: center.x - halfWidth, y: center.y - halfHeight)
            let topRight = CGPoint(x: center.x + halfWidth, y: center.y - halfHeight)
            let bottomLeft = CGPoint(x: center.x - halfWidth, y: center.y + halfHeight)
            let bottomRight = CGPoint(x: center.x + halfWidth, y: center.y + halfHeight)
            
            // 如果有旋轉角度，旋轉這些點
            if pad.rotatedAngle != 0 {
                let rotatedTL = rotatePoint(topLeft, around: center, angle: pad.rotatedAngle)
                let rotatedTR = rotatePoint(topRight, around: center, angle: pad.rotatedAngle)
                let rotatedBL = rotatePoint(bottomLeft, around: center, angle: pad.rotatedAngle)
                let rotatedBR = rotatePoint(bottomRight, around: center, angle: pad.rotatedAngle)
                
                // 找出旋轉後的極值
                minX = min(minX, rotatedTL.x, rotatedTR.x, rotatedBL.x, rotatedBR.x)
                minY = min(minY, rotatedTL.y, rotatedTR.y, rotatedBL.y, rotatedBR.y)
                maxX = max(maxX, rotatedTL.x, rotatedTR.x, rotatedBL.x, rotatedBR.x)
                maxY = max(maxY, rotatedTL.y, rotatedTR.y, rotatedBL.y, rotatedBR.y)
            } else {
                // 不旋轉，直接找極值
                minX = min(minX, center.x - halfWidth)
                minY = min(minY, center.y - halfHeight)
                maxX = max(maxX, center.x + halfWidth)
                maxY = max(maxY, center.y + halfHeight)
            }
        }
        
        // 添加額外的邊距
        minX -= paddingInset
        minY -= paddingInset
        maxX += paddingInset
        maxY += paddingInset
        
        return CGRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
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
