//
//  UserSettingsView.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/9.
//

import SwiftUI

struct UserSettingsView: View {
    @ObservedObject var viewState: ICLayoutViewState
    @ObservedObject var dragPreviewManager: DragPreviewManager
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            Form {
                // 視圖選項
                Section(header: Text("視圖選項")) {
                    Toggle("顯示標籤", isOn: $viewState.showLabels)
                    Toggle("顯示網格", isOn: $viewState.showGrid)
                    Toggle("顯示連線", isOn: $viewState.showConnections)
                    Toggle("顯示IC邊框", isOn: $viewState.showICBoundary)
                }
                
                // 拖曳選項
                Section(header: Text("拖曳選項")) {
                    Toggle("使用拖曳預覽", isOn: $dragPreviewManager.previewEnabled)
                    
                    if dragPreviewManager.previewEnabled {
                        Text("拖曳時會先顯示半透明預覽，需要確認後才會實際移動元件")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // IC邊框設定
                Section(header: Text("IC邊框設定")) {
                    Toggle("使用固定尺寸邊框", isOn: $viewState.useFixedICBoundary)
                    
                    if viewState.useFixedICBoundary {
                        HStack {
                            Text("寬度")
                            Spacer()
                            TextField("寬度", value: $viewState.fixedICBoundaryWidth, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }
                        
                        HStack {
                            Text("高度")
                            Spacer()
                            TextField("高度", value: $viewState.fixedICBoundaryHeight, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }
                    }
                    
                    Toggle("邊界超出警告", isOn: $viewState.warnOnBoundaryExceed)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
