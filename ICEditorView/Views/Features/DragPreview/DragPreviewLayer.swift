//
//  DragPreviewLayer.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/9.
//

import SwiftUI

struct DragPreviewLayer: View {
    @ObservedObject var previewManager: DragPreviewManager
    let padDimensions: [UUID: ModelPADDimension]
    let pads: [UUID: ModelPAD]
    
    var body: some View {
        ZStack {
            // 繪製所有預覽元件
            ForEach(Array(previewManager.originalPositions.keys), id: \.self) { componentID in
                if let pad = pads[componentID],
                   let originalPosition = previewManager.originalPositions[componentID] {
                    
                    // 計算預覽位置
                    let previewPosition = CGPoint(
                        x: originalPosition.x + previewManager.dragOffset.width,
                        y: originalPosition.y + previewManager.dragOffset.height
                    )
                    
                    // 繪製預覽PAD
                    PADPreviewView(
                        pad: pad,
                        dimension: pad.padDimensionID != nil ? padDimensions[pad.padDimensionID!] : nil,
                        position: previewPosition
                    )
                }
            }
            
            // 顯示當前拖曳座標
            if previewManager.isDragging {
                Text("X: \(Int(previewManager.dragCurrentPosition.x)), Y: \(Int(previewManager.dragCurrentPosition.y))")
                    .font(.system(size: 14, weight: .medium))
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.black.opacity(0.7))
                    )
                    .foregroundColor(.white)
                    .position(previewManager.dragCurrentPosition)
                    .offset(y: -50) // 在拖曳點上方顯示
            }
        }
    }
}

