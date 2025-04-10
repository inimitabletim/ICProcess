//
//  ICLayoutMainView.swift
//  ICEditorView
//
//  Created by TimChi on 2025/3/27.
//

import SwiftUI

struct ICLayoutMainView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var appModeManager = AppModeManager()
    @StateObject private var viewModel = ICLayoutViewModel()
    @StateObject private var viewState = ICLayoutViewState()
    @StateObject private var layoutManager = ICLayoutManager()
    
    private let companyName = "TimChi"
    private let appVersion = "v0.0.5"
    
    var body: some View {
        VStack(spacing: 0) {
            // 頂部工具列
            topToolbar
            
            // 根據當前模式切換不同視圖
            if appModeManager.currentMode == .user {
//                ICLayoutUserView(layoutManager: layoutManager, viewModel: viewModel, viewState: viewState)
                ICLayoutViewModernized(layoutManager: layoutManager, viewModel: viewModel, viewState: viewState)
            } else {
                ICLayoutDeveloperView(
                    viewModel: appModeManager.isDeveloperModeAvailable ?
                              DeveloperICLayoutViewModel() : viewModel,
                    viewState: viewState
                )
            }
        }
        .environmentObject(appModeManager)
    }
    
    // 頂部工具列
    private var topToolbar: some View {
        HStack {
            Button(action: { self.presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "arrowshape.turn.up.backward")
                    .topBarImageStyle()
            }
            
            Spacer()
            
            // 公司名稱與版本 - 添加手勢識別
            VStack(alignment: .leading, spacing: 2) {
                Text("IC排列視覺化工具")
                    .topBarTextStyle()
                    // 添加點擊手勢來觸發開發者模式
                    .onTapGesture {
                        appModeManager.handleSecretTap()
                    }
            }
            
            Spacer()
            
            // 只在開發者按鈕可見時顯示
            if appModeManager.isDeveloperModeAvailable && appModeManager.isDeveloperButtonVisible {
                Button(action: {
                    appModeManager.toggleMode()
                }) {
                    HStack {
                        Image(systemName: appModeManager.currentMode == .user ?
                                "wrench" : "person")
                        Text(appModeManager.currentMode == .user ?
                             "開發模式" : "使用者模式")
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .topBarBackgroundStyle()
        .navigationBarHidden(true)
    }
}
