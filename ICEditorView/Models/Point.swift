//
//  Point.swift
//  ICPinAssignmentViewer
//
//  Created by TimChi on 2025/3/26.
//

import Foundation

// MARK: - 座標點模型
struct Point: Codable, Hashable {
    var x: Double
    var y: Double
    
    // 計算與另一個點的距離
    func distance(to other: Point) -> Double {
        return sqrt(pow(x - other.x, 2) + pow(y - other.y, 2))
    }
        
    // 旋轉點（相對於給定中心點）
    func rotated(around center: Point, by angle: Double) -> Point {
        // 先平移到原點
        let translatedX = x - center.x
        let translatedY = y - center.y
        
        // 旋轉
        let rotatedX = translatedX * cos(angle) - translatedY * sin(angle)
        let rotatedY = translatedX * sin(angle) + translatedY * cos(angle)
        
        // 平移回原位置
        return Point(x: rotatedX + center.x, y: rotatedY + center.y)
    }
}
