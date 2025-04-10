//
//  PositionEditorView.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/9.
//

import SwiftUI

struct PositionEditorView: View {
    let componentID: UUID
    let layoutManager: ICLayoutManager
    let onClose: () -> Void
    
    @State private var xPosition: Int = 0
    @State private var yPosition: Int = 0
    @State private var originalX: Int = 0
    @State private var originalY: Int = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 當前位置顯示
                HStack {
                    Text("當前位置:")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("X: \(originalX), Y: \(originalY)")
                        .foregroundColor(.secondary)
                }
                
                // X座標編輯
                VStack(alignment: .leading, spacing: 6) {
                    Text("X座標")
                        .font(.headline)
                    
                    HStack {
                        TextField("X座標", value: $xPosition, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        // 微調按鈕
                        Button(action: { xPosition -= 10 }) {
                            Image(systemName: "minus.circle")
                                .foregroundColor(.red)
                        }
                        
                        Button(action: { xPosition -= 1 }) {
                            Image(systemName: "minus")
                                .foregroundColor(.red)
                        }
                        
                        Button(action: { xPosition += 1 }) {
                            Image(systemName: "plus")
                                .foregroundColor(.green)
                        }
                        
                        Button(action: { xPosition += 10 }) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // Y座標編輯
                VStack(alignment: .leading, spacing: 6) {
                    Text("Y座標")
                        .font(.headline)
                    
                    HStack {
                        TextField("Y座標", value: $yPosition, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        // 微調按鈕
                        Button(action: { yPosition -= 10 }) {
                            Image(systemName: "minus.circle")
                                .foregroundColor(.red)
                        }
                        
                        Button(action: { yPosition -= 1 }) {
                            Image(systemName: "minus")
                                .foregroundColor(.red)
                        }
                        
                        Button(action: { yPosition += 1 }) {
                            Image(systemName: "plus")
                                .foregroundColor(.green)
                        }
                        
                        Button(action: { yPosition += 10 }) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // 重置按鈕
                Button(action: {
                    xPosition = originalX
                    yPosition = originalY
                }) {
                    Label("重置為原始位置", systemImage: "arrow.counterclockwise")
                        .foregroundColor(.accentColor)
                }
                .padding(.top, 12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("編輯位置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        onClose()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("確定") {
                        updatePosition()
                        onClose()
                    }
                }
            }
            .onAppear {
                loadCurrentPosition()
            }
        }
    }
    
    // 載入當前位置
    private func loadCurrentPosition() {
        if let pad = layoutManager.pads[componentID] {
            xPosition = Int(pad.centerLocateX)
            yPosition = Int(pad.centerLocateY)
            originalX = xPosition
            originalY = yPosition
        } else if let pin = layoutManager.pins[componentID],
                  let position = pin.getPosition(pads: layoutManager.pads) {
            xPosition = Int(position.x)
            yPosition = Int(position.y)
            originalX = xPosition
            originalY = yPosition
        }
    }
    
    // 更新位置
    private func updatePosition() {
        if var pad = layoutManager.pads[componentID] {
            pad.centerLocateX = Int32(xPosition)
            pad.centerLocateY = Int32(yPosition)
            layoutManager.updatePAD(pad)
        }
        // 注意：PIN的位置通常由其關聯的PAD決定，所以這裡不直接更新PIN
    }
}
