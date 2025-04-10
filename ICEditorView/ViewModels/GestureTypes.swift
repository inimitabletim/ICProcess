//
//  GestureTypes.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/9.
//

import SwiftUI


/// 手勢修飾符選項集
public struct GestureModifiers: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let shift = GestureModifiers(rawValue: 1 << 0)
    public static let control = GestureModifiers(rawValue: 1 << 1)
    public static let option = GestureModifiers(rawValue: 1 << 2)
    public static let command = GestureModifiers(rawValue: 1 << 3)
    public static let rightClick = GestureModifiers(rawValue: 1 << 4)
    public static let multiTouch = GestureModifiers(rawValue: 1 << 5)
}
