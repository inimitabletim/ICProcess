//
//  ICBoundarySettingsView.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/8.
//

import SwiftUI

/// IC邊框設定對話框
struct ICBoundarySettingsView: View {
    // MARK: - 數據模型
    @ObservedObject var viewState: ICLayoutViewState
    @Binding var isPresented: Bool
    
    // MARK: - 臨時狀態值
    @State private var widthText: String = ""
    @State private var heightText: String = ""
    @State private var useFixedBoundary: Bool = false
    @State private var showWarnings: Bool = true
    
    // MARK: - 初始化
    init(viewState: ICLayoutViewState, isPresented: Binding<Bool>) {
        self.viewState = viewState
        self._isPresented = isPresented
        
        // 初始化狀態值
        self._widthText = State(initialValue: String(Int(viewState.fixedICSize.width)))
        self._heightText = State(initialValue: String(Int(viewState.fixedICSize.height)))
        self._useFixedBoundary = State(initialValue: viewState.useFixedICBoundary)
        self._showWarnings = State(initialValue: viewState.warnOnBoundaryExceed)
    }
    
    // MARK: - 主視圖
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("邊框尺寸設定")) {
                    HStack {
                        Text("寬度")
                        Spacer()
                        TextField("寬度", text: $widthText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    
                    HStack {
                        Text("高度")
                        Spacer()
                        TextField("高度", text: $heightText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                }
                
                Section(header: Text("邊框選項")) {
                    Toggle("使用固定尺寸邊框", isOn: $useFixedBoundary)
                    Toggle("顯示邊界超出警告", isOn: $showWarnings)
                }
                
                Section(header: Text("預設值")) {
                    Button("套用預設尺寸 (4000 x 4000)") {
                        widthText = "4000"
                        heightText = "4000"
                    }
                    .foregroundColor(.blue)
                }
                
                Section(footer: Text("註：固定邊框以坐標原點(0,0)為中心繪製").font(.caption).foregroundColor(.secondary)) {
                    // 說明文字空區域
                }
            }
            .navigationTitle("IC邊框設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("套用") {
                        applySettings()
                        isPresented = false
                    }
                }
            }
        }
        .onAppear {
            // 顯示時載入當前設定
            widthText = String(Int(viewState.fixedICSize.width))
            heightText = String(Int(viewState.fixedICSize.height))
            useFixedBoundary = viewState.useFixedICBoundary
            showWarnings = viewState.warnOnBoundaryExceed
        }
    }
    
    // MARK: - 方法
    
    /// 套用設定到視圖狀態
    private func applySettings() {
        // 解析寬度和高度
        if let width = Int(widthText), width > 0,
           let height = Int(heightText), height > 0 {
            viewState.fixedICSize = CGSize(width: CGFloat(width), height: CGFloat(height))
        }
        
        // 套用其他設定
        viewState.useFixedICBoundary = useFixedBoundary
        viewState.warnOnBoundaryExceed = showWarnings
    }
}

//#Preview {
//    ICBoundarySettingsView()
//}
