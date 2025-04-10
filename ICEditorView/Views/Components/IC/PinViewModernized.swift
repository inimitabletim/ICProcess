//
//  PinViewModernized.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/8.
//

import SwiftUI

// MARK: - 現代化視覺元件

/// 現代化的Pin視圖元件
struct PinViewModernized: View {
    let pin: ModelPin
    let position: CGPoint
    var isSelected: Bool = false
    var showLabel: Bool = true
    var padSize: CGFloat = 12
    
    var body: some View {
        ZStack {
            // 陰影效果
            if isSelected {
                Circle()
                    .fill(Color.orange.opacity(0.3))
                    .frame(width: padSize + 12, height: padSize + 12)
                    .position(position)
                    .blur(radius: 6)
            }
            
            // Pin圓點
            Circle()
                .fill(isSelected ? Color.orange : Color.blue)
                .frame(width: padSize, height: padSize)
                .position(position)
                .shadow(color: (isSelected ? Color.orange : Color.blue).opacity(0.5), radius: 4, x: 0, y: 2)
            
            // 外圈高亮(選中時)
            if isSelected {
                Circle()
                    .stroke(Color.orange, lineWidth: 2)
                    .frame(width: padSize + 6, height: padSize + 6)
                    .position(position)
            }
            
            // Pin標籤
            if showLabel {
                Text("Pin-\(pin.pinIndex)")
                    .font(.system(size: padSize > 12 ? 11 : 9, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(UIColor.systemBackground).opacity(0.9))
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
                    .offset(y: padSize + 12)
                    .position(position)
            }
        }
    }
}
