//
//  AppModeManager.swift
//  ICEditorView
//
//  Created by TimChi on 2025/3/27.
//

import SwiftUI

// 應用模式枚舉
enum AppMode {
    case user     // 使用者模式
    case developer // 開發者模式
}

// 模式管理器 - 負責全局模式狀態
class AppModeManager: ObservableObject {
    @Published var currentMode: AppMode = .user
    @Published var isDeveloperButtonVisible: Bool = false
    
    // 條件性啟用開發者模式的機制
    #if DEBUG
    var isDeveloperModeAvailable: Bool = true
    #else
    var isDeveloperModeAvailable: Bool = false
    #endif
    
    // 密碼驗證計數器
    private var secretTapCounter = 0
    private var secretTimer: Timer?
    
    // 切換模式 (如果允許)
    func toggleMode() {
        if isDeveloperModeAvailable {
            withAnimation {
                currentMode = currentMode == .user ? .developer : .user
            }
        }
    }
    
    // 處理密碼手勢 - 連續點擊5次應用標題可顯示開發者按鈕
    func handleSecretTap() {
        secretTapCounter += 1
        
        // 重置已有的計時器
        secretTimer?.invalidate()
        
        // 設置新的計時器 - 3秒內沒有完成組合則重置計數
        secretTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.secretTapCounter = 0
        }
        
        // 達到5次點擊後顯示開發者按鈕
        if secretTapCounter >= 5 {
            withAnimation(.spring()) {
                isDeveloperButtonVisible = true
            }
            secretTapCounter = 0
            secretTimer?.invalidate()
            
            // 10秒後自動隱藏按鈕
            secretTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
                withAnimation {
                    self?.isDeveloperButtonVisible = false
                }
            }
        }
    }
    
    // 自定義初始化器 - 可以根據需要設置初始模式
    init(initialMode: AppMode = .user) {
        #if DEBUG
        self.currentMode = initialMode
        #else
        self.currentMode = .user
        #endif
    }
}
