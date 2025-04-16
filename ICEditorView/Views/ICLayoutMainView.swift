//
//  ICLayoutMainView.swift
//  ICEditorView
//
//  Created by TimChi on 2025/3/27.
//

import SwiftUI

struct ICLayoutMainView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject var gestureState = GestureState()
    @StateObject private var appModeManager = AppModeManager()
    @StateObject private var viewModel = ICLayoutViewModel()
    @StateObject private var viewState = ICLayoutViewState()
    @StateObject private var layoutManager = ICLayoutManager()
    
    // MARK: - 界面狀態
    @State var showModeFeedback = false
    @State var feedbackMessage = ""

    // MARK: - CSV匯入狀態
    @State var isImportingCSV = false
    
    @State var showingImportAlert = false
    @State var importAlertMessage = ""
    @State var importAlertIsSuccess = false
    
    private let companyName = "TimChi"
    private let appVersion = "v0.0.5"
    
    var body: some View {
        VStack(spacing: 0) {
            // 頂部工具列
            topToolbar
            
            // 根據當前模式切換不同視圖
            if appModeManager.currentMode == .user {
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
            Button(action: {
                self.presentationMode.wrappedValue.dismiss()
                performHapticFeedback(.light)
            }) {
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
            
            // 使用原生 Menu API 實現檔案選單
            Menu {
                // 匯入 CSV
                Button(action: {
                    isImportingCSV = true
                    performHapticFeedback(.medium)
                }) {
                    Label("匯入 CSV", systemImage: "square.and.arrow.down")
                }
                
                // 匯出 CSV
                Button(action: {
                    showFeedback("匯出 CSV 功能尚未實現", true)
                }) {
                    Label("匯出 CSV", systemImage: "square.and.arrow.up")
                }
                
                Divider()
                
                // 儲存佈局
                Button(action: {
                    showFeedback("儲存佈局功能尚未實現", true)
                }) {
                    Label("儲存佈局", systemImage: "folder")
                }
                
                // 載入佈局
                Button(action: {
                    showFeedback("載入佈局功能尚未實現", true)
                }) {
                    Label("載入佈局", systemImage: "folder.badge.plus")
                }
            } label: {
                Image(systemName: "plus")
                    .topBarImageStyle()
            }
            .menuStyle(DefaultMenuStyle())
            .menuIndicator(.hidden)
            
            // 只在開發者按鈕可見時顯示
            if appModeManager.isDeveloperModeAvailable && appModeManager.isDeveloperButtonVisible {
                Button(action: {
                    appModeManager.toggleMode()
                    performHapticFeedback(.medium)
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
        .fileImporter(
            isPresented: $isImportingCSV,
            allowedContentTypes: [.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            handleCSVImport(result: result)
        }
    }
    
    // MARK: - 觸覺反饋
    
    /// 執行觸覺反饋
    func performHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare() // 預先準備，減少延遲
        generator.impactOccurred()
    }
    
    // MARK: - CSV 匯入處理
    
    func handleCSVImport(result: Result<[URL], Error>) {
        do {
            // 獲取選擇的檔案URL
            let selectedFiles = try result.get()
            
            // 確保選擇了檔案
            guard let selectedFile = selectedFiles.first else {
                showImportAlert(success: false, message: "未選擇檔案")
                return
            }
            
            // 取得檔案存取權限
            if selectedFile.startAccessingSecurityScopedResource() {
                defer { selectedFile.stopAccessingSecurityScopedResource() }
                
                // 使用增強版匯入功能處理檔案
                let importResult = viewModel.loadFromCSVWithValidation(url: selectedFile)
                
                // 如果成功，更新layoutManager中的數據
                if importResult.success {
                    handleSuccessfulImport(importResult)
                } else {
                    // 顯示失敗信息
                    showImportAlert(success: false, message: importResult.message)
                    showFeedback("匯入失敗", true)
                }
            } else {
                showImportAlert(success: false, message: "無法存取選擇的檔案")
            }
        } catch {
            showImportAlert(success: false, message: "檔案選擇錯誤: \(error.localizedDescription)")
        }
    }
    
    private func handleSuccessfulImport(_ importResult: (success: Bool, message: String)) {
        // 同步更新layoutManager數據
        updateLayoutManagerFromViewModel()
        
        // 執行layoutManager的數據一致性檢查
        let managerValidationResult = layoutManager.validateAndCleanData()
        
        // 重置視圖
        withAnimation(.spring()) {
            // ✅ 確保導入後更新視圖狀態
            viewState.useFixedICBoundary = false  // 切換到動態邊界模式
            viewState.resetView()
            resetView()
        }
        
        // 增加一致性檢查報告
        var successMessage = importResult.message
        if managerValidationResult.totalIssues > 0 {
            successMessage += "\n額外修復了 \(managerValidationResult.totalIssues) 個數據一致性問題"
        }
        
        // 顯示結果提示
        showImportAlert(success: true, message: successMessage)
        showFeedback("匯入成功，數據已驗證", true)
    }
    
    // MARK: - 數據處理
    
    private func updateLayoutManagerFromViewModel() {
        // 將ViewModel中的數據轉換為LayoutManager需要的格式
        var pinDict: [UUID: ModelPin] = [:]
        var padDict: [UUID: ModelPAD] = [:]
        
        // 轉換Pin數據
        for pin in viewModel.pins {
            pinDict[pin.id] = pin
        }
        
        // 轉換PAD數據
        for pad in viewModel.pads {
            padDict[pad.id] = pad
        }
        
        // 更新LayoutManager數據
        layoutManager.pins = pinDict
        layoutManager.pads = padDict
        layoutManager.padDimensions = viewModel.padDimensions
        
        // 記錄歷史
        layoutManager.recordHistory()
    }
    
    private func resetView() {
        withAnimation(.spring()) {
            gestureState.resetView()
        }
        showFeedback("重置視圖", true)
    }
    
    private func showImportAlert(success: Bool, message: String) {
        importAlertIsSuccess = success
        importAlertMessage = message
        showingImportAlert = true
    }
    
    /// 顯示操作反饋提示 - 簡化版
    private func showFeedback(_ message: String, _ withHaptic: Bool) {
        feedbackMessage = message
        
        // 視覺反饋
        withAnimation(.easeInOut(duration: 0.3)) {
            showModeFeedback = true
        }
        
        // 觸覺反饋
        if withHaptic {
            performHapticFeedback(.medium)
        }
        
        // 延遲隱藏反饋
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showModeFeedback = false
            }
        }
    }
}
