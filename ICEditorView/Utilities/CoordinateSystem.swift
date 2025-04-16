//
//  CoordinateSystem.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/16.
//

import Foundation
import SwiftUI

/// 統一座標系統管理器
class CoordinateSystem {
    // MARK: - 座標類型
    
    /// 統一的座標點表示
    struct ICPoint: Codable, Hashable {
        var x: Double
        var y: Double
        
        // MARK: - 初始化方法
        
        init(x: Double, y: Double) {
            self.x = x
            self.y = y
        }
        
        // 從 CGPoint 轉換
        init(_ point: CGPoint) {
            self.x = Double(point.x)
            self.y = Double(point.y)
        }
        
        // 從 Int32 轉換
        init(x: Int32, y: Int32) {
            self.x = Double(x)
            self.y = Double(y)
        }
        
        // MARK: - 轉換方法
        
        /// 轉換為 CGPoint
        func toCGPoint() -> CGPoint {
            return CGPoint(x: CGFloat(x), y: CGFloat(y))
        }
        
        /// 轉換為整數座標
        func toIntPoint() -> (x: Int, y: Int) {
            return (Int(x.rounded()), Int(y.rounded()))
        }
        
        /// 轉換為 Int32 座標
        func toInt32Point() -> (x: Int32, y: Int32) {
            return (Int32(x.rounded()), Int32(y.rounded()))
        }
        
        // MARK: - 座標運算
        
        /// 計算與另一點的距離
        func distance(to other: ICPoint) -> Double {
            return sqrt(pow(x - other.x, 2) + pow(y - other.y, 2))
        }
        
        /// 旋轉點（相對於給定中心點）
        func rotated(around center: ICPoint, by angleInDegrees: Double) -> ICPoint {
            // 將角度轉換為弧度
            let angleInRadians = angleInDegrees * .pi / 180.0
            
            // 先平移到原點
            let translatedX = x - center.x
            let translatedY = y - center.y
            
            // 旋轉
            let rotatedX = translatedX * cos(angleInRadians) - translatedY * sin(angleInRadians)
            let rotatedY = translatedX * sin(angleInRadians) + translatedY * cos(angleInRadians)
            
            // 平移回原位置
            return ICPoint(x: rotatedX + center.x, y: rotatedY + center.y)
        }
        
        /// 加入偏移量
        func offset(dx: Double, dy: Double) -> ICPoint {
            return ICPoint(x: self.x + dx, y: self.y + dy)
        }
        
        /// 使用縮放比例調整座標
        func scaled(by scale: Double, relativeTo origin: ICPoint = ICPoint(x: Double(0), y: Double(0))) -> ICPoint {
            let translatedX = x - origin.x
            let translatedY = y - origin.y
            
            let scaledX = translatedX * scale
            let scaledY = translatedY * scale
            
            return ICPoint(x: Double(scaledX + origin.x), y: Double(scaledY + origin.y))
        }
    }
    
    // MARK: - 座標系統轉換
    
    /// 模型座標與螢幕座標轉換
    struct ViewTransformation {
        var scale: Double
        var offset: (x: Double, y: Double)
        
        /// 內容座標轉換為螢幕座標
        func contentToScreen(_ point: ICPoint) -> ICPoint {
            return ICPoint(
                x: point.x * scale + offset.x,
                y: point.y * scale + offset.y
            )
        }
        
        /// 螢幕座標轉換為內容座標
        func screenToContent(_ point: ICPoint) -> ICPoint {
            return ICPoint(
                x: (point.x - offset.x) / scale,
                y: (point.y - offset.y) / scale
            )
        }
    }
    
    // MARK: - 幾何計算
    
    /// 判斷點是否在旋轉矩形內
    static func isPointInRotatedRect(
        point: ICPoint,
        rectCenter: ICPoint,
        width: Double,
        height: Double,
        rotationDegrees: Double
    ) -> Bool {
        // 將點轉換到以矩形中心為原點的座標系
        let dx = point.x - rectCenter.x
        let dy = point.y - rectCenter.y
        
        // 旋轉角度轉換為弧度（負號是為了反向旋轉）
        let angle = -rotationDegrees * .pi / 180.0
        
        // 反向旋轉點，使矩形恢復水平
        let cosAngle = cos(angle)
        let sinAngle = sin(angle)
        
        let rotatedX = dx * cosAngle - dy * sinAngle
        let rotatedY = dx * sinAngle + dy * cosAngle
        
        // 檢查點是否在矩形內
        return abs(rotatedX) <= width / 2 && abs(rotatedY) <= height / 2
    }
    
    /// 計算矩形的四個角點（考慮旋轉）
    static func getRotatedRectCorners(
        center: ICPoint,
        width: Double,
        height: Double,
        rotationDegrees: Double
    ) -> [ICPoint] {
        let halfWidth = width / 2
        let halfHeight = height / 2
        
        // 未旋轉時的四個角點
        let topLeft = ICPoint(x: center.x - halfWidth, y: center.y - halfHeight)
        let topRight = ICPoint(x: center.x + halfWidth, y: center.y - halfHeight)
        let bottomLeft = ICPoint(x: center.x - halfWidth, y: center.y + halfHeight)
        let bottomRight = ICPoint(x: center.x + halfWidth, y: center.y + halfHeight)
        
        // 旋轉四個角點
        return [
            topLeft.rotated(around: center, by: rotationDegrees),
            topRight.rotated(around: center, by: rotationDegrees),
            bottomLeft.rotated(around: center, by: rotationDegrees),
            bottomRight.rotated(around: center, by: rotationDegrees)
        ]
    }
    
    /// 計算旋轉矩形的邊界框
    static func getRotatedRectBounds(
        center: ICPoint,
        width: Double,
        height: Double,
        rotationDegrees: Double
    ) -> (minX: Double, minY: Double, maxX: Double, maxY: Double) {
        let corners = getRotatedRectCorners(
            center: center,
            width: width,
            height: height,
            rotationDegrees: rotationDegrees
        )
        
        // 計算極值
        let xs = corners.map { $0.x }
        let ys = corners.map { $0.y }
        
        return (
            minX: xs.min() ?? 0,
            minY: ys.min() ?? 0,
            maxX: xs.max() ?? 0,
            maxY: ys.max() ?? 0
        )
    }
    
    // MARK: - 碰撞檢測工具
    
    /// 增強的碰撞檢測（精確考慮旋轉）
    static func enhancedHitTest(
        point: ICPoint,
        componentCenter: ICPoint,
        width: Double,
        height: Double,
        rotationDegrees: Double,
        tolerance: Double = 10.0
    ) -> Bool {
        // 擴大檢測範圍
        let expandedWidth = width + tolerance * 2
        let expandedHeight = height + tolerance * 2
        
        return isPointInRotatedRect(
            point: point,
            rectCenter: componentCenter,
            width: expandedWidth,
            height: expandedHeight,
            rotationDegrees: rotationDegrees
        )
    }
}
