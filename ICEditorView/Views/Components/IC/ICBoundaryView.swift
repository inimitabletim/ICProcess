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
        
        for pad in layoutManager.pads.values {
            // 取得PAD尺寸資訊
            let padWidth: CGFloat
            let padHeight: CGFloat
            
            // 如果有關聯的PAD尺寸，則使用該尺寸
            if let dimensionID = pad.padDimensionID, let dimension = layoutManager.padDimensions[dimensionID] {
                padWidth = CGFloat(dimension.width)
                padHeight = CGFloat(dimension.height)
            } else {
                // 若無關聯尺寸，使用預設值(可依需求調整)
                padWidth = 50
                padHeight = 30
            }
            
            // 計算PAD的四邊界座標
            let padLeft = CGFloat(pad.centerLocateX) - padWidth / 2
            let padRight = CGFloat(pad.centerLocateX) + padWidth / 2
            let padTop = CGFloat(pad.centerLocateY) - padHeight / 2
            let padBottom = CGFloat(pad.centerLocateY) + padHeight / 2
            
            minX = min(minX, padLeft)
            minY = min(minY, padTop)
            maxX = max(maxX, padRight)
            maxY = max(maxY, padBottom)
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
}
