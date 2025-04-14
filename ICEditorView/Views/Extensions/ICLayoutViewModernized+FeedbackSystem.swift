//
//  ICLayoutViewModernized+FeedbackSystem.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/11.
//

import SwiftUI
import Combine

// MARK: - 反饋系統擴展
extension ICLayoutViewModernized {
    
    /// 反饋級別枚舉 - 決定反饋的強度
    enum FeedbackIntensity {
        case light    // 輕微反饋 - 用於輕微操作確認
        case medium   // 中等反饋 - 用於一般操作確認
        case strong   // 強力反饋 - 用於重要操作或警告
        
        /// 轉換為震動強度值
        var hapticIntensity: CGFloat {
            switch self {
            case .light:   return 0.2
            case .medium:  return 0.5
            case .strong:  return 1.0
            }
        }
        
        /// 轉換為顯示持續時間
        var displayDuration: TimeInterval {
            switch self {
            case .light:   return 1.0
            case .medium:  return 1.5
            case .strong:  return 2.0
            }
        }
    }
    
    /// 反饋類型枚舉 - 決定反饋的視覺效果和音效
    enum FeedbackType {
        case success      // 成功反饋
        case warning      // 警告反饋
        case info         // 資訊反饋
        case error        // 錯誤反饋
        
        /// 獲取反饋顏色
        var color: Color {
            switch self {
            case .success: return .green
            case .warning: return .orange
            case .info:    return .blue
            case .error:   return .red
            }
        }
        
        /// 獲取圖標名稱
        var iconName: String {
            switch self {
            case .success: return "checkmark.circle"
            case .warning: return "exclamationmark.triangle"
            case .info:    return "info.circle"
            case .error:   return "xmark.circle"
            }
        }
    }
    
    /// 提供綜合反饋 - 結合視覺、觸覺和音效反饋
    func provideFeedback(
        message: String,
        type: FeedbackType = .info,
        intensity: FeedbackIntensity = .medium
    ) {
        // 1. 視覺反饋
        let enhancedMessage = enhanceMessageWithEmoji(message, type: type)
        feedbackMessage = enhancedMessage
        
        withAnimation(.easeInOut(duration: 0.2)) {
            showModeFeedback = true
        }
        
        // 2. 觸覺反饋
        performHapticFeedback(intensity: intensity.hapticIntensity)
        
        // 3. 音效反饋 (未實現，可在後續階段添加)
        // playFeedbackSound(type: type)
        
        // 4. 延遲隱藏視覺反饋
        DispatchQueue.main.asyncAfter(deadline: .now() + intensity.displayDuration) {
            withAnimation {
                showModeFeedback = false
            }
        }
    }
    
    /// 增強消息文本 - 添加表情符號增強視覺效果
    private func enhanceMessageWithEmoji(_ message: String, type: FeedbackType) -> String {
        let emoji: String
        
        switch type {
        case .success: emoji = "✅ "
        case .warning: emoji = "⚠️ "
        case .info:    emoji = "ℹ️ "
        case .error:   emoji = "❌ "
        }
        
        return emoji + message
    }
        
    /// 提供不同類型的觸覺反饋
    func performHapticWithType(type: FeedbackType) {
        switch type {
        case .success:
            // 成功反饋 - 使用輕柔且令人愉悅的觸覺
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
        case .warning:
            // 警告反饋 - 使用較強的觸覺
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            
        case .error:
            // 錯誤反饋 - 使用強烈的觸覺
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            
        case .info:
            // 資訊反饋 - 使用輕微的觸覺
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
        
    /// 顯示迷你反饋 - 僅在元件附近短暫顯示的小型反饋
    func showMiniTooltip(
        message: String,
        at position: CGPoint,
        duration: TimeInterval = 1.0
    ) {
        // 在階段一實作簡化版，使用主反饋系統
        showFeedback(message, false)
    }
    
    /// 顯示情境輔助提示 - 基於用戶操作提供智能提示
    func showContextualHint(for context: GestureContext) {
        // 根據不同情境提供不同的提示
        
        // 1. 在編輯模式下選中多個元件
        if viewState.isEditMode && layoutManager.selectedComponents.count > 1 {
            showMiniTooltip(
                message: "提示：可以批量移動選中的元件",
                at: CGPoint(
                    x: gestureState.lastCursorX,
                    y: gestureState.lastCursorY
                )
            )
            return
        }
        
        // 2. 使用者嘗試在非編輯模式下移動元件
        if !viewState.isEditMode &&
           context.targetComponentID != nil &&
           context.translation.width + context.translation.height > 20 {
            
            showMiniTooltip(
                message: "提示：進入編輯模式以移動元件",
                at: CGPoint(
                    x: gestureState.lastCursorX,
                    y: gestureState.lastCursorY
                )
            )
            return
        }
        
        // 後續可以添加更多情境提示
    }
}

// MARK: - 擴充顯示元件

/// 增強版迷你工具提示視圖 - 顯示在特定位置的小型提示
struct MiniTooltipView: View {
    let message: String
    let position: CGPoint
    var type: ICLayoutViewModernized.FeedbackType = .info
    
    var body: some View {
        HStack(spacing: 4) {
            // 圖標
            Image(systemName: type.iconName)
                .font(.system(size: 12))
                .foregroundColor(type.color)
            
            // 訊息
            Text(message)
                .font(.system(size: 12))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 1)
        )
        .position(position)
        .transition(.opacity)
    }
}

/// 增強版反饋提示視圖 - 支援不同類型的反饋
struct EnhancedFeedbackToast: View {
    let message: String
    var type: ICLayoutViewModernized.FeedbackType = .info
    
    var body: some View {
        HStack(spacing: 8) {
            // 圖標
            Image(systemName: type.iconName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(type.color)
            
            // 訊息
            Text(message)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .transition(.opacity)
    }
}
