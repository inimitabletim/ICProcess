//
//  ICLayoutDebugView.swift
//  ICPinAssignmentViewer
//
//  Created by TimChi on 2025/3/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct ICLayoutDebugView: View {
    @StateObject private var layoutManager = ICLayoutManager()
    @State private var isFileImporterPresented = false
    @State private var isShowingSettings = false
    @State private var alertInfo: (show: Bool, title: String, message: String) = (false, "", "")
    @State private var statusMessage = "歡迎使用IC排列視覺化工具"
    
    // 系統提供的文檔選擇器支援的格式
    let supportedTypes: [UTType] = [UTType.commaSeparatedText]
    
    var body: some View {
        VStack(spacing: 0) {
            // 頂部工具列
            toolbarView
                .frame(height: 50)
                .background(Color.blue.opacity(0.1))
            
//            // 主顯示區域
//            ICLayoutView(layoutManager: layoutManager)
//                .overlay(
//                    // 狀態訊息
//                    Text(statusMessage)
//                        .font(.system(size: 14))
//                        .padding(8)
//                        .background(Color.black.opacity(0.6))
//                        .foregroundColor(.white)
//                        .cornerRadius(5)
//                        .padding(),
//                    alignment: .bottom
//                )
        }
        .navigationBarTitle("IC排列視覺化工具", displayMode: .inline)
        .navigationBarItems(
            trailing: Button(action: { isShowingSettings.toggle() }) {
                Image(systemName: "gear")
            }
        )
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: supportedTypes,
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .alert(isPresented: $alertInfo.show) {
            Alert(
                title: Text(alertInfo.title),
                message: Text(alertInfo.message),
                dismissButton: .default(Text("確定"))
            )
        }
        .sheet(isPresented: $isShowingSettings) {
            settingsView
        }
    }
    
    // MARK: - 子視圖
    
    /// 頂部工具列
    private var toolbarView: some View {
        HStack(spacing: 15) {
            // CSV匯入按鈕
            Button(action: { isFileImporterPresented = true }) {
                Label("匯入CSV", systemImage: "square.and.arrow.down")
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(5)
            }
            
            Spacer()
            
            // 顯示元件數量
            Group {
                Text("Pin: \(layoutManager.pins.count)")
                Text("PAD: \(layoutManager.pads.count)")
                Text("已選擇: \(layoutManager.selectedComponents.count)")
            }
            .font(.system(size: 14))
            .padding(.horizontal, 5)
            
            Spacer()
            
            // 操作按鈕
            Button(action: { layoutManager.clearSelection() }) {
                Label("清除選擇", systemImage: "xmark.circle")
                    .labelStyle(.iconOnly)
            }
            .padding(.horizontal, 5)
            
            Button(action: generateTestData) {
                Label("產生測試資料", systemImage: "wand.and.stars")
                    .labelStyle(.iconOnly)
            }
            .padding(.horizontal, 5)
        }
        .padding(.horizontal)
    }
    
    /// 設定視圖
    private var settingsView: some View {
        NavigationView {
            Form {
                Section(header: Text("顯示設定")) {
                    Toggle("顯示標籤", isOn: .constant(true))
                    Toggle("顯示連線", isOn: .constant(true))
                    Toggle("顯示網格", isOn: .constant(true))
                }
                
                Section(header: Text("關於")) {
                    Text("IC排列視覺化工具")
                        .font(.headline)
                    Text("版本: 1.0")
                    Text("開發者: AIP ESD Team")
                }
            }
            .navigationBarTitle("設定", displayMode: .inline)
            .navigationBarItems(trailing: Button("完成") {
                isShowingSettings = false
            })
        }
    }
    
    // MARK: - 功能方法
    
    /// 處理文件匯入
    private func handleFileImport(_ result: Result<[URL], Error>) {
        do {
            // 取得選擇的檔案URL
            let fileURLs = try result.get()
            guard let selectedFile = fileURLs.first else {
                showAlert(title: "錯誤", message: "未選擇檔案")
                return
            }
            
            // 確保有檔案存取權
            if selectedFile.startAccessingSecurityScopedResource() {
                defer {
                    selectedFile.stopAccessingSecurityScopedResource()
                }
                
                // 匯入CSV
                let importResult = layoutManager.importFromCSV(url: selectedFile)
                
                if importResult.success {
                    statusMessage = importResult.message
                } else {
                    showAlert(title: "匯入失敗", message: importResult.message)
                }
            } else {
                showAlert(title: "錯誤", message: "無法存取選擇的檔案")
            }
            
        } catch {
            showAlert(title: "檔案處理錯誤", message: error.localizedDescription)
        }
    }
    
    /// 產生測試資料
    private func generateTestData() {
        // 清除現有資料
        layoutManager.pins.removeAll()
        layoutManager.pads.removeAll()
        layoutManager.padDimensions.removeAll()
        
        // 使用測試資料生成器
        layoutManager.loadTestData()
        
        // 更新狀態訊息
        statusMessage = "已產生測試元件 (Pin: \(layoutManager.pins.count), PAD: \(layoutManager.pads.count))"
        
        // 同時建立測試CSV檔案 (用於測試檔案匯入功能)
        if let fileURL = TestDataGenerator.generateCSVTestData() {
            // 顯示建立的檔案路徑
            print("📝 測試CSV檔案已儲存於: \(fileURL.path)")
        }
    }
    
    /// 顯示警告對話框
    private func showAlert(title: String, message: String) {
        alertInfo = (true, title, message)
    }
}

#Preview {
    ICLayoutDebugView()
}
