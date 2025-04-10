//
//  ICLayoutDeveloperView.swift
//  ICEditorView
//
//  Created by TimChi on 2025/3/27.
//

import SwiftUI

struct ICLayoutDeveloperView: View, DeveloperModeViewProtocol {
    @ObservedObject var viewModel: ICLayoutViewModel
    @ObservedObject var viewState: ICLayoutViewState
    @StateObject private var layoutManager = ICLayoutManager()
    
    // 開發者特定狀態
    @State private var isDebugPanelVisible: Bool = false
    @State private var selectedDebugTab: DebugTab = .info
    @State private var testInProgress: Bool = false
    
    enum DebugTab {
        case info, `import`, export, test
    }
    
    var body: some View {
        ZStack {
            // 使用基礎使用者視圖
//            ICLayoutUserView(layoutManager: layoutManager, viewModel: viewModel, viewState: viewState)
            
            // 開發者覆蓋層和控制項
            VStack {
                HStack {
                    Spacer()
                    
                    // 開發者工具按鈕
                    Button(action: {
                        withAnimation {
                            isDebugPanelVisible.toggle()
                        }
                    }) {
                        Image(systemName: "hammer.fill")
                            .padding(10)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .padding()
                }
                
                Spacer()
            }
            
            // 調試面板 (條件顯示)
            if isDebugPanelVisible {
                debugPanel
            }
        }
    }
    
    // 調試面板
    private var debugPanel: some View {
        VStack {
            // 面板標題
            HStack {
                Text("開發者工具")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isDebugPanelVisible = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding(.bottom, 5)
            
            // 標籤選擇器
            Picker("Debug Options", selection: $selectedDebugTab) {
                Text("信息").tag(DebugTab.info)
                Text("導入").tag(DebugTab.import)
                Text("導出").tag(DebugTab.export)
                Text("測試").tag(DebugTab.test)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.bottom, 10)
            
            // 選項卡內容
            ScrollView {
                switch selectedDebugTab {
                case .info:
                    debugInfoTab
                case .import:
                    debugImportTab
                case .export:
                    debugExportTab
                case .test:
                    debugTestTab
                }
            }
        }
        .frame(width: 300, height: 400)
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 10)
        .transition(.move(edge: .trailing))
    }
    
    // 調試信息標籤頁
    private var debugInfoTab: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("元件統計")
                .font(.subheadline)
                .bold()
            
            HStack {
                Text("Pin 數量:")
                Spacer()
                Text("\(viewModel.pins.count)")
            }
            
            HStack {
                Text("PAD 數量:")
                Spacer()
                Text("\(viewModel.pads.count)")
            }
            
            HStack {
                Text("已選擇元件:")
                Spacer()
                Text("\(viewModel.selectedPinIDs.count + viewModel.selectedPADIDs.count)")
            }
            
            Divider()
            
            Text("視圖狀態")
                .font(.subheadline)
                .bold()
            
            HStack {
                Text("當前縮放:")
                Spacer()
                Text(String(format: "%.2f", viewState.scale))
            }
            
            HStack {
                Text("當前偏移 X:")
                Spacer()
                Text(String(format: "%.1f", viewState.offset.width))
            }
            
            HStack {
                Text("當前偏移 Y:")
                Spacer()
                Text(String(format: "%.1f", viewState.offset.height))
            }
            
            Button(action: {
                showDebugInfo()
            }) {
                Text("顯示完整調試信息")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .padding(.top)
        }
    }
    
    // 導入標籤頁
    private var debugImportTab: some View {
        VStack(spacing: 15) {
            Button(action: {
                // 導入CSV檔案
                // 這裡需要實現檔案選擇功能
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("導入CSV檔案")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            Button(action: {
                // 生成測試數據
                if let developerVM = viewModel as? DeveloperICLayoutViewModel {
                    developerVM.generateTestData()
                }
            }) {
                HStack {
                    Image(systemName: "wand.and.stars")
                    Text("生成測試數據")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            Divider()
            
            Text("導入選項")
                .font(.subheadline)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Toggle("使用標準化座標", isOn: .constant(true))
            Toggle("自動關聯相同名稱", isOn: .constant(true))
            Toggle("導入後清除選擇", isOn: .constant(false))
        }
    }
    
    // 導出標籤頁
    private var debugExportTab: some View {
        VStack(spacing: 15) {
            Button(action: {
                exportDebugData()
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("導出調試數據")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            Button(action: {
                // 導出布局截圖
                // 實現截圖功能
            }) {
                HStack {
                    Image(systemName: "camera")
                    Text("導出布局截圖")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            Divider()
            
            Text("導出選項")
                .font(.subheadline)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 導出格式選項
            Picker("導出格式", selection: .constant(0)) {
                Text("JSON").tag(0)
                Text("CSV").tag(1)
                Text("XML").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // 其他導出選項...
            Toggle("包含調試信息", isOn: .constant(true))
            Toggle("僅導出選擇項", isOn: .constant(false))
        }
    }
    
    // 測試標籤頁
    private var debugTestTab: some View {
        VStack(spacing: 15) {
            Button(action: {
                testPerformance()
            }) {
                HStack {
                    Image(systemName: "speedometer")
                    Text("執行性能測試")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            if testInProgress {
                ProgressView("測試中...")
                    .padding()
            }
            
            Divider()
            
            Text("測試選項")
                .font(.subheadline)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading) {
                Text("測試數據大小")
                Picker("測試數據大小", selection: .constant(1)) {
                    Text("小 (50元件)").tag(0)
                    Text("中 (200元件)").tag(1)
                    Text("大 (1000元件)").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding(.bottom, 5)
            
            Toggle("測試渲染性能", isOn: .constant(true))
            Toggle("測試手勢響應", isOn: .constant(true))
            Toggle("測試記憶體使用", isOn: .constant(false))
        }
    }
    
    // MARK: - DeveloperModeViewProtocol實現
    
    func zoomIn() {
        // 直接使用UserModeView中的實現
        withAnimation(.spring()) {
            viewState.scale *= 1.2
            viewState.lastScale = viewState.scale
        }
    }
    
    func zoomOut() {
        // 直接使用UserModeView中的實現
        withAnimation(.spring()) {
            viewState.scale /= 1.2
            viewState.lastScale = viewState.scale
        }
    }
    
    func resetView() {
        // 直接使用UserModeView中的實現
        withAnimation(.spring()) {
            viewState.resetView()
        }
    }
    
    func showDebugInfo() {
        // 顯示完整調試信息
        if let developerVM = viewModel as? DeveloperICLayoutViewModel {
            let debugInfo = developerVM.exportDebugInformation()
            print(debugInfo)
            
            // 這裡可以添加更直觀的UI顯示，例如警告框
            // ...
        }
    }
    
    func exportDebugData() {
        // 導出調試數據
        if let developerVM = viewModel as? DeveloperICLayoutViewModel {
            let debugInfo = developerVM.exportDebugInformation()
            
            // 這裡需要實現檔案保存功能
            // 例如使用SwiftUI的FileExporter
            // ...
            
            print("正在導出調試數據...")
        }
    }
    
    func testPerformance() {
        // 執行性能測試
        testInProgress = true
        
        // 模擬測試過程
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // 執行實際的性能測試
            // ...
            
            self.testInProgress = false
        }
    }
}
