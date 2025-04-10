//
//  DragConfirmDialog.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/9.
//

import SwiftUI

struct DragConfirmDialog: View {
    @ObservedObject var previewManager: DragPreviewManager
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    onCancel()
                }
            
            // 確認對話框
            VStack(spacing: 16) {
                Text("確認移動位置?")
                    .font(.headline)
                
                Text("新位置: (\(Int(previewManager.dragCurrentPosition.x)), \(Int(previewManager.dragCurrentPosition.y)))")
                
                HStack {
                    Button("取消") {
                        onCancel()
                    }
                    .buttonStyle(BorderedButtonStyle())
                    
                    Spacer()
                    
                    Button("確認") {
                        onConfirm()
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: Color.black.opacity(0.2), radius: 12)
            )
            .frame(width: 280)
        }
    }
}
