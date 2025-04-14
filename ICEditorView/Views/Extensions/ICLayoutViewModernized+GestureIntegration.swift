//
//  ICLayoutViewModernized+GestureIntegration.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/11.
//

import SwiftUI
import Combine

// MARK: - 訂閱管理器類別
/// 專門管理 Combine 訂閱的類別
final class SubscriptionManager: ObservableObject {
    var subscriptions = Set<AnyCancellable>()
    
    func store(_ subscription: AnyCancellable) {
        subscriptions.insert(subscription)
    }
    
    func removeAll() {
        subscriptions.removeAll()
    }
}

// MARK: - 訂閱管理器單例
extension SubscriptionManager {
    /// 單例實例，用於全域管理訂閱
    static let shared = SubscriptionManager()
}

// MARK: - 混合手勢整合擴展
extension ICLayoutViewModernized {
    
    /// 配置混合手勢系統 - 將智能手勢與工具模式整合
    func configureHybridGestures() -> AnyGesture<Void> {
        switch viewState.selectedTool {
        case .pan:
            // 「平移模式」平移和縮放都可用
            return AnyGesture(
                createPanGesture()
                    .simultaneously(with: createZoomGesture())
                    .map { _ in }
            )
        
        case .zoom:
            // 「縮放模式」縮放和平移都可用
            return AnyGesture(
                createZoomGesture()
                    .simultaneously(with: createPanGesture())
                    .map { _ in }
            )
            
        case .select, .browse:
            // 使用更靈活的同時手勢處理
            return AnyGesture(
                configureContextAwareGestures().map { _ in }
            )
            
        case .addPin, .addPad, .connect:
            // 特殊工具模式，同時支援平移和縮放
            return AnyGesture(
                createPanGesture()
                    .simultaneously(with: createZoomGesture())
                    .map { _ in }
            )
        }
    }
    
    /// 創建專用平移手勢
    private func createPanGesture() -> some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                // 如果未處於平移狀態，初始化
                if !gestureState.isPanning {
                    gestureState.isPanning = true
                    gestureState.panStartLocation = value.startLocation
                    
                    // 提供輕微觸覺反饋
                    performHapticFeedback(intensity: 0.1)
                }
                
                // 更新游標位置
                gestureState.lastCursorX = value.location.x
                gestureState.lastCursorY = value.location.y
                
                // 平移視圖
                withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.8)) {
                    gestureState.offset = CGSize(
                        width: gestureState.lastOffset.width + value.translation.width,
                        height: gestureState.lastOffset.height + value.translation.height
                    )
                }
            }
            .onEnded { value in
                // 更新最終偏移值
                gestureState.lastOffset = gestureState.offset
                gestureState.isPanning = false
                gestureState.panStartLocation = nil
                
                // 計算總移動距離
                let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                
                // 提供反饋
                if distance > 5 {
                    performHapticFeedback(intensity: 0.2)
                    showFeedback("平移完成", true)
                }
            }
    }
    
    /// 創建專用縮放手勢
    private func createZoomGesture() -> some Gesture {
        MagnificationGesture(minimumScaleDelta: 0.01)
            .onChanged { value in
                // 設置縮放狀態，不再檢查其他條件
                gestureState.isZooming = true
                
                // 計算新的縮放值
                let newScale = gestureState.lastScale * value
                
                // 應用縮放，保持在合理範圍內
                withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 0.85)) {
                    gestureState.scale = min(max(gestureState.minScale, newScale), gestureState.maxScale)
                }
                
                // 縮放超過閾值時提供輕微觸覺反饋
                if abs(gestureState.scale - gestureState.lastScale) > 0.05 {
                    performHapticFeedback(intensity: 0.15)
                }
            }
            .onEnded { _ in
                // 保存最終縮放值
                gestureState.lastScale = gestureState.scale
                gestureState.isZooming = false
                
                // 提供反饋
                performHapticFeedback(intensity: 0.2)
                showFeedback("縮放: \(Int(gestureState.scale * 100))%", true)
            }
    }
    
    /// 處理工具列與手勢系統的協同工作
    func handleToolbarToolChange() -> Void {
        // 重置手勢狀態
        gestureState.resetGestureState()
        
        // 根據新工具提供適當的反饋
        switch viewState.selectedTool {
        case .select:
            showFeedback("已切換到選擇工具", true)
            
        case .pan:
            showFeedback("已切換到平移工具", true)
            
        case .zoom:
            showFeedback("已切換到縮放工具", true)
            
        case .addPin:
            showFeedback("已切換到新增Pin工具", true)
            
        case .addPad:
            showFeedback("已切換到新增PAD工具", true)
            
        case .connect:
            showFeedback("已切換到連接工具", true)
            
        case .browse:
            showFeedback("已切換到瀏覽模式", true)
        }
    }
    
    /// 監聽模式變化並適應手勢行為
    func setupModeChangeObservers() {
        // 不使用捕獲列表（不寫 [weak self] 或 [unowned self]）
        // 在 SwiftUI 結構體中直接使用 self 是安全的
        let subscription = viewState.objectWillChange
            .sink { _ in
                // 當工具模式改變時，重設手勢狀態
                if self.viewState.isEditMode != self.gestureState.isEditMode {
                    self.gestureState.resetGestureState()
                    self.gestureState.isEditMode = self.viewState.isEditMode
                }
            }
        
        // 使用共享的訂閱管理器儲存訂閱
        SubscriptionManager.shared.store(subscription)
    }
    
    /// 處理鍵盤修飾符變化
    func handleKeyModifiersChange(modifiers: GestureModifiers) {
        // 更新手勢狀態中的修飾符
        gestureState.gestureModifiers = modifiers
        
        // 當Shift鍵狀態改變時，自動切換多選模式
        let wasMultiSelectMode = isMultiSelectMode
        isMultiSelectMode = modifiers.contains(.shift)
        
        // 如果多選模式狀態發生變化，顯示反饋
        if wasMultiSelectMode != isMultiSelectMode {
            showFeedback(isMultiSelectMode ? "多選模式已開啟" : "多選模式已關閉", false)
        }
    }
    
    /// 處理Apple Pencil相關行為
    func handlePencilInteraction(pressure: CGFloat, at location: CGPoint) {
        // 在階段一中，僅提供基本支援
        
        // 根據壓力級別提供不同的行為
        if pressure > 0.8 {
            // 高壓力 - 強烈反饋
            performHapticFeedback(intensity: 0.8)
        } else if pressure > 0.4 {
            // 中等壓力 - 標準反饋
            performHapticFeedback(intensity: 0.4)
        }
    }
    
    /// 應用修飾符到操作中
    func applyGestureModifiers(to intent: UserIntent, with modifiers: GestureModifiers) -> UserIntent {
        var modifiedIntent = intent
        
        // 根據不同修飾符調整行為
        if modifiers.contains(.shift) {
            // Shift鍵通常用於多選或保持比例
            if intent == .selectComponent {
                modifiedIntent = .multiSelect
            }
        }
        
        if modifiers.contains(.option) {
            // Option/Alt鍵可以用於複製操作
            // 在階段一不實現
        }
        
        return modifiedIntent
    }
}

// MARK: - 擴展屬性與工具方法

extension ICLayoutViewModernized {
    // 將這些變量和方法從臨時屬性轉移到正式擴展
    
    /// 儲存取消訂閱的容器
    private struct AssociatedKeys {
        static var cancellablesKey = "ICLayoutViewModernized.cancellables"
    }
    
    /// 存儲 Combine 訂閱對象的集合
    var cancellables: Set<AnyCancellable> {
        get {
            if let existing = objc_getAssociatedObject(self, &AssociatedKeys.cancellablesKey) as? Set<AnyCancellable> {
                return existing
            }
            let new = Set<AnyCancellable>()
            objc_setAssociatedObject(self, &AssociatedKeys.cancellablesKey, new, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return new
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.cancellablesKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 檢查工具模式是否為直接操作模式
    var isDirectManipulationMode: Bool {
        return viewState.selectedTool == .select || viewState.selectedTool == .browse
    }
    
    /// 檢查是否為iPad模式 - 用於優化觸控體驗
    var isIPadMode: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
}
