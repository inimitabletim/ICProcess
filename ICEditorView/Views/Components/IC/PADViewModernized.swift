//
//  PADViewModernized.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/8.
//

import SwiftUI

/// 現代化的PAD視圖元件
struct PADViewModernized: View {
    let pad: ModelPAD
    let dimension: ModelPADDimension?
    let isSelected: Bool
    let showLabel: Bool
    
    var body: some View {
        let width = CGFloat(dimension?.width ?? 50)
        let height = CGFloat(dimension?.height ?? 30)
        let centerPosition = CGPoint(x: CGFloat(pad.centerLocateX), y: CGFloat(pad.centerLocateY))
        
        ZStack {
            // 整個PAD元件容器
            ZStack {
                // 陰影效果 (選中時)
                if isSelected {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.orange.opacity(0.3))
                        .frame(width: width + 8, height: height + 8)
                        .blur(radius: 6)
                }
                
                // PAD主矩形
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.orange.opacity(0.7) : Color.green.opacity(0.6))
                    .frame(width: width, height: height)
                    .shadow(color: (isSelected ? Color.orange : Color.green).opacity(0.5), radius: 4, x: 0, y: 2)
                
                // PAD邊框
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.orange : Color.green, lineWidth: 1.5)
                    .frame(width: width, height: height)
            }
            // 先旋轉整個容器
            .rotationEffect(.degrees(pad.rotatedAngle))
            // 再設定位置
            .position(centerPosition)
            
            // PAD名稱 (保持不旋轉)
            if showLabel {
                Text(pad.name)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(UIColor.systemBackground).opacity(0.9))
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
                    // 標籤位置不受旋轉影響
                    .position(CGPoint(x: centerPosition.x, y: centerPosition.y + height / 2 + 16))
            }
        }
    }
}

