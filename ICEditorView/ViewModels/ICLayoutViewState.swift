//
//  ICLayoutViewState.swift
//  ICEditorView
//
//  Created by TimChi on 2025/3/27.
//

import SwiftUI
import Combine

class ICLayoutViewState: ObservableObject {
    // 縮放與平移狀態
    @Published var scale: CGFloat = 1.0
    @Published var lastScale: CGFloat = 1.0
    @Published var offset: CGSize = .zero
    @Published var lastOffset: CGSize = .zero
    
    // 顯示選項
    @Published var showLabels: Bool = true
    @Published var showConnections: Bool = true
    @Published var showGrid: Bool = true
    
    // 調試選項
    @Published var showDebugInfo: Bool = false
    
    // 視圖模式
    @Published var isEditMode: Bool = false
    @Published var selectedTool: LayoutTool = .select

    
    // 📝 添加額外屬性字典 - 用於存儲動態屬性
    @Published var extraProperties: [String: Any] = [:]
    
    // 在 ICLayoutViewState 類中添加
    @Published var showICBoundary: Bool = true            // 是否顯示IC邊框
    @Published var useFixedICBoundary: Bool = false       // 是否使用固定尺寸邊框
    @Published var fixedICSize: CGSize = CGSize(width: 4000, height: 4000)  // 固定IC尺寸
    @Published var warnOnBoundaryExceed: Bool = true      // 是否在元件超出邊界時顯示警告
    
    // 工具類型 - 添加原始值支援
    enum LayoutTool: Int {
        case select = 0
        case pan = 1
        case zoom = 2
        case addPin = 3
        case addPad = 4
        case connect = 5
        case browse = 6  // 📝 添加瀏覽模式
        
        var icon: String {
            switch self {
            case .select: return "arrow.up.left.and.down.right.magnifyingglass"
            case .pan: return "hand.draw.fill"
            case .zoom: return "magnifyingglass"
            case .addPin: return "pin.fill"
            case .addPad: return "square.fill"
            case .connect: return "link"
            case .browse: return "hand.draw.fill"  // 瀏覽模式使用與平移相同的圖標
            }
        }
        
        var name: String {
            switch self {
            case .select: return "選擇模式"
            case .pan: return "平移模式"
            case .zoom: return "縮放模式"
            case .addPin: return "新增Pin模式"
            case .addPad: return "新增PAD模式"
            case .connect: return "連接模式"
            case .browse: return "瀏覽模式"
            }
        }
        
        var color: Color {
            switch self {
            case .select: return .blue
            case .pan: return .green
            case .zoom: return .purple
            case .addPin: return .red
            case .addPad: return .indigo
            case .connect: return .teal
            case .browse: return .green  // 瀏覽模式使用與平移相同的顏色
            }
        }
    }
    
    // 觸覺反饋產生器
    private var impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    // 重置視圖狀態
    func resetView() {
        scale = 1.0
        lastScale = 1.0
        offset = .zero
        lastOffset = .zero
    }
    
    // 提供觸覺反饋
    func performHapticFeedback(intensity: CGFloat = 0.5) {
        impactGenerator.impactOccurred(intensity: intensity)
    }
    
    // 移動視圖 (透過方向按鈕)
    func moveView(direction: MoveDirection, distance: CGFloat = 50.0) {
        withAnimation(.spring()) {
            switch direction {
            case .up:
                offset.height += distance
            case .down:
                offset.height -= distance
            case .left:
                offset.width += distance
            case .right:
                offset.width -= distance
            }
        }
        
        // 更新最後偏移值
        lastOffset = offset
        
        // 提供反饋
        performHapticFeedback(intensity: 0.3)
    }
    
    // MARK: - IC邊框相關屬性
    
    /// 重設邊框相關設定
    func resetBoundarySettings() {
        showICBoundary = true
        useFixedICBoundary = false
        fixedICSize = CGSize(width: 4000, height: 4000)
        warnOnBoundaryExceed = true
    }
    
    // 移動方向枚舉
    enum MoveDirection {
        case up, down, left, right
    }
}

// MARK: - 擴展 ViewState 模型
extension ICLayoutViewState {
    // 添加屬性以支持自動模式切換
    var previousTool: LayoutTool? {
        get {
            if let value = self.extraProperties["previousTool"] as? Int,
               let tool = LayoutTool(rawValue: value) {
                return tool
            }
            return nil
        }
        set {
            if let value = newValue?.rawValue {
                self.extraProperties["previousTool"] = value
            } else {
                self.extraProperties.removeValue(forKey: "previousTool")
            }
        }
    }
    
    // 添加屬性以支持iPad觸控提示
    var showTouchHints: Bool {
        get {
            return self.extraProperties["showTouchHints"] as? Bool ?? true
        }
        set {
            self.extraProperties["showTouchHints"] = newValue
        }
    }
    
    // 添加懸停元件ID的屬性訪問器
    var hoveredComponentID: UUID? {
        get {
            return self.extraProperties["hoveredComponentID"] as? UUID
        }
        set {
            if let newID = newValue {
                self.extraProperties["hoveredComponentID"] = newID
            } else {
                self.extraProperties.removeValue(forKey: "hoveredComponentID")
            }
        }
    }
}

// 擴展 View 以提供觸覺反饋
extension View {
    func withHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
        }
    }
}

// 添加簡單的屬性存取偵錯
extension ICLayoutViewState {
    // 偵錯用的屬性存取追蹤
    func logPropertyAccess(property: String, value: Any?, operation: String = "讀取") {
        #if DEBUG
        print("📊 屬性存取: \(operation) \(property) = \(String(describing: value))")
        #endif
    }
}
