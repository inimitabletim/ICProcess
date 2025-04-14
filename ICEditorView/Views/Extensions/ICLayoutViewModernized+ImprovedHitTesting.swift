//
//  ICLayoutViewModernized+ImprovedHitTesting.swift.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/14.
//

import SwiftUI
import Combine

extension ICLayoutViewModernized {
    
    /// 改進的碰撞檢測方法
    func enhancedHitTest(_ location: CGPoint) -> UUID? {
        // 轉換螢幕座標到內容座標系
        let adjustedLocation = screenToContentCoordinate(screenPoint: location)
        
        // 擴大點擊檢測範圍 - 根據iPad觸控尺寸優化
        let touchRadius: CGFloat = iPadMode ? 22.0 : 15.0
        
        // 先檢查Pin (因為通常較小且在頂層)
        for (pinID, pin) in layoutManager.pins {
            if let position = getPinPosition(for: pin) {
                // 計算點擊位置與Pin中心的距離
                let distance = distanceBetween(position, adjustedLocation)
                
                // 使用較寬鬆的檢測範圍以提升用戶體驗
                // 對於已選中的Pin，使用更大的點擊範圍，方便操作
                let isSelected = layoutManager.selectedComponents.contains(pinID)
                let effectiveRadius = isSelected ? touchRadius * 1.5 : touchRadius
                
                if distance < effectiveRadius {
                    return pinID
                }
            }
        }
        
        // 再檢查PAD (因為通常較大且在底層)
        var closestPadID: UUID? = nil
        var closestDistance: CGFloat = .infinity
        
        for (padID, pad) in layoutManager.pads {
            // 獲取PAD的尺寸
            let dimension = pad.padDimensionID != nil ?
                layoutManager.padDimensions[pad.padDimensionID!] : nil
            let width = CGFloat(dimension?.width ?? 50)
            let height = CGFloat(dimension?.height ?? 30)
            
            // 擴大檢測範圍
            let expandedWidth = width + 10
            let expandedHeight = height + 10
            
            // 考慮PAD的旋轉角度
            let inRect = pointInRotatedRect(
                point: adjustedLocation,
                rectCenter: CGPoint(x: CGFloat(pad.centerLocateX), y: CGFloat(pad.centerLocateY)),
                width: expandedWidth,
                height: expandedHeight,
                rotation: .degrees(pad.rotatedAngle)
            )
            
            if inRect {
                // 計算點擊位置到PAD中心的距離
                let padCenter = CGPoint(x: CGFloat(pad.centerLocateX), y: CGFloat(pad.centerLocateY))
                let distance = distanceBetween(padCenter, adjustedLocation)
                
                // 記錄最近的PAD
                if distance < closestDistance {
                    closestDistance = distance
                    closestPadID = padID
                }
            }
        }
        
        // 如果找到PAD，返回ID
        if let padID = closestPadID {
            return padID
        }
        
        // 處理邊緣情況：檢查點擊位置是否非常接近某個PAD邊緣
        for (padID, pad) in layoutManager.pads {
            let padCenter = CGPoint(x: CGFloat(pad.centerLocateX), y: CGFloat(pad.centerLocateY))
            let distance = distanceBetween(padCenter, adjustedLocation)
            
            let dimension = pad.padDimensionID != nil ?
                layoutManager.padDimensions[pad.padDimensionID!] : nil
            let maxDimension = max(CGFloat(dimension?.width ?? 50), CGFloat(dimension?.height ?? 30))
            
            // 如果點擊位置在PAD邊緣附近(考慮旋轉的情況)
            if distance < maxDimension/2 + touchRadius {
                return padID
            }
        }
        
        // 沒有找到元件
        return nil
    }
    
    /// 顯示點擊檢測反饋 - 用於調試
    func showHitTestFeedback(at location: CGPoint) {
        if showDebugInfo {
            // 轉換螢幕座標到內容座標系
            let contentLocation = screenToContentCoordinate(screenPoint: location)
            
            print("➡️ 點擊位置：螢幕(\(Int(location.x)), \(Int(location.y))), 內容(\(Int(contentLocation.x)), \(Int(contentLocation.y)))")
            
            // 使用增強的碰撞檢測
            if let componentID = enhancedHitTest(location) {
                if let pin = layoutManager.pins[componentID] {
                    print("✅ 點擊到Pin：\(pin.name) (ID: \(componentID))")
                } else if let pad = layoutManager.pads[componentID] {
                    print("✅ 點擊到PAD：\(pad.name) (ID: \(componentID))")
                }
            } else {
                print("❌ 未點擊到任何元件")
            }
        }
    }
}
