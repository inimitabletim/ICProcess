//
//  RotationEditorView.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/9.
//

import SwiftUI

struct RotationEditorView: View {
    let pad: ModelPAD
    let layoutManager: ICLayoutManager
    let onClose: () -> Void
    
    @State private var rotationAngle: Double
    @State private var originalAngle: Double
    
    init(pad: ModelPAD, layoutManager: ICLayoutManager, onClose: @escaping () -> Void) {
        self.pad = pad
        self.layoutManager = layoutManager
        self.onClose = onClose
        self._rotationAngle = State(initialValue: pad.rotatedAngle)
        self._originalAngle = State(initialValue: pad.rotatedAngle)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 當前角度顯示
                HStack {
                    Text("當前角度:")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f°", originalAngle))
                        .foregroundColor(.secondary)
                }
                
                // 角度滑桿
                VStack(alignment: .leading, spacing: 12) {
                    Text("旋轉角度: \(Int(rotationAngle))°")
                        .font(.headline)
                    
                    Slider(value: $rotationAngle, in: 0...360, step: 1)
                        .accentColor(.blue)
                }
                
                // 預設角度快速按鈕
                HStack(spacing: 12) {
                    ForEach([0, 90, 180, 270], id: \.self) { angle in
                        Button(action: {
                            rotationAngle = Double(angle)
                        }) {
                            Text("\(angle)°")
                                .frame(minWidth: 50)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Int(rotationAngle) == angle ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Int(rotationAngle) == angle ? Color.blue : Color.clear, lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // 微調按鈕
                HStack(spacing: 16) {
                    Button(action: { rotationAngle = max(0, rotationAngle - 10) }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                    
                    Button(action: { rotationAngle = max(0, rotationAngle - 1) }) {
                        Image(systemName: "minus.circle")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                    
                    Button(action: { rotationAngle = min(360, rotationAngle + 1) }) {
                        Image(systemName: "plus.circle")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                    
                    Button(action: { rotationAngle = min(360, rotationAngle + 10) }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                }
                .padding(.top, 8)
                
                // 重置按鈕
                Button(action: {
                    rotationAngle = originalAngle
                }) {
                    Label("重置為原始角度", systemImage: "arrow.counterclockwise")
                        .foregroundColor(.accentColor)
                }
                .padding(.top, 12)
                
                // PAD預覽
                VStack {
                    Text("預覽")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    ZStack {
                        // 背景網格
                        Grid(horizontalCount: 10, verticalCount: 10, lineWidth: 0.5)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                            .frame(width: 200, height: 200)
                        
                        // PAD形狀
                        Rectangle()
                            .fill(Color.green.opacity(0.3))
                            .frame(
                                width: CGFloat(layoutManager.padDimensions[pad.padDimensionID ?? UUID()]?.width ?? 50),
                                height: CGFloat(layoutManager.padDimensions[pad.padDimensionID ?? UUID()]?.height ?? 30)
                            )
                            .overlay(
                                Rectangle()
                                    .stroke(Color.green, lineWidth: 1.5)
                            )
                            .rotationEffect(.degrees(rotationAngle))
                    }
                    .frame(width: 200, height: 200)
                    .background(Color(UIColor.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("編輯旋轉角度")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        onClose()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("確定") {
                        updateRotation()
                        onClose()
                    }
                }
            }
        }
    }
    
    // 更新旋轉角度
    private func updateRotation() {
        var updatedPad = pad
        updatedPad.rotatedAngle = rotationAngle
        layoutManager.updatePAD(updatedPad)
    }
}
