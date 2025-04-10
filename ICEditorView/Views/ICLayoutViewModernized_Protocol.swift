//
//  ICLayoutViewModernized_Protocol.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/9.
//

import SwiftUI

/// 定義 IC 排列視圖的基本協議，便於不同視圖共享行為
protocol UserModeViewProtocol {
    var layoutManager: ICLayoutManager { get }
    var viewModel: ICLayoutViewModel { get }
    var viewState: ICLayoutViewState { get }
    
    // 基本操作
    func zoomIn()
    func zoomOut()
    func resetView()
    
    // 元件操作
    func selectComponent(id: UUID)
    func showComponentDetails(id: UUID)
}

/// 移動方向枚舉
enum MoveDirection {
    case up, down, left, right
}

