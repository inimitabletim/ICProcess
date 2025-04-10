//
//  GridBackgroundModernized.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/9.
//

import SwiftUI

struct GridBackgroundModernized: View {
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let gridSize: CGFloat = 20
                let gridColor = Color.primary.opacity(0.1)
                
                // 繪製水平線
                for y in stride(from: 0, to: size.height, by: gridSize) {
                    let path = Path { p in
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: size.width, y: y))
                    }
                    context.stroke(path, with: .color(gridColor), lineWidth: 0.5)
                }
                
                // 繪製垂直線
                for x in stride(from: 0, to: size.width, by: gridSize) {
                    let path = Path { p in
                        p.move(to: CGPoint(x: x, y: 0))
                        p.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    context.stroke(path, with: .color(gridColor), lineWidth: 0.5)
                }
                
                // 繪製主要參考線
                let mainLineColor = Color.primary.opacity(0.2)
                let centerXPath = Path { p in
                    p.move(to: CGPoint(x: size.width / 2, y: 0))
                    p.addLine(to: CGPoint(x: size.width / 2, y: size.height))
                }
                let centerYPath = Path { p in
                    p.move(to: CGPoint(x: 0, y: size.height / 2))
                    p.addLine(to: CGPoint(x: size.width, y: size.height / 2))
                }
                context.stroke(centerXPath, with: .color(mainLineColor), lineWidth: 1.0)
                context.stroke(centerYPath, with: .color(mainLineColor), lineWidth: 1.0)
            }
        }
        .allowsHitTesting(false)
    }
}
