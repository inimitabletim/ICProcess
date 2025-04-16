//
//  ICLayoutViewProtocol.swift
//  ICEditorView
//
//  Created by TimChi on 2025/3/27.
//

import SwiftUI

// 共用視圖協議 - 定義所有 IC 視圖必須提供的基本功能
protocol ICLayoutViewProtocol: View {
    var viewModel: ICLayoutViewModel { get }
    var viewState: ICLayoutViewState { get }
    
    // 基本互動方法
    func zoomIn()
    func zoomOut()
    func resetView()
}

// 開發者模式特定協議
protocol DeveloperModeViewProtocol: ICLayoutViewProtocol {
    // 開發者特定功能
    func showDebugInfo()
    func exportDebugData()
    func testPerformance()
}
