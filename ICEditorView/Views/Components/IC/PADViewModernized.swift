//
//  PADViewModernized.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/8.
//

//
//  PADViewModernized.swift
//  ICEditorView
//

import SwiftUI

/// 現代化的PAD視圖元件，添加45度增量旋轉控制點
struct PADViewModernized: View {
    let pad: ModelPAD
    let dimension: ModelPADDimension?
    let isSelected: Bool
    let showLabel: Bool
    @EnvironmentObject var viewState: ICLayoutViewState
    @EnvironmentObject var layoutManager: ICLayoutManager
    
    // 旋轉控制相關狀態
    @State private var isDraggingRotationHandle: Bool = false
    @State private var rotationStart: CGPoint? = nil
    
    // 45度角度吸附值陣列
    private let snapAngles: [Double] = [0, 45, 90, 135, 180, 225, 270, 315]
    
    var body: some View {
        let width = CGFloat(dimension?.width ?? 50)
        let height = CGFloat(dimension?.height ?? 30)
        let centerPosition = CGPoint(x: CGFloat(pad.centerLocateX), y: CGFloat(pad.centerLocateY))
        
        ZStack {
            // 整個PAD元件容器
            ZStack {
                // 陰影效果 (選中時)
                if isSelected {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.orange.opacity(0.3))
                        .frame(width: width + 8, height: height + 8)
                        .blur(radius: 6)
                }
                
                // PAD主矩形
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.orange.opacity(0.7) : Color.green.opacity(0.6))
                    .frame(width: width, height: height)
                    .shadow(color: (isSelected ? Color.orange : Color.green).opacity(0.5), radius: 4, x: 0, y: 2)
                
                // PAD邊框
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.orange : Color.green, lineWidth: 1.5)
                    .frame(width: width, height: height)
            }
            // 先旋轉整個容器
            .rotationEffect(.degrees(pad.rotatedAngle))
            // 再設定位置
            .position(centerPosition)
            
            // PAD名稱 (保持不旋轉)
            if showLabel {
                Text(pad.name)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(UIColor.systemBackground).opacity(0.9))
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
                    // 標籤位置不受旋轉影響
                    .position(CGPoint(x: centerPosition.x, y: centerPosition.y + height / 2 + 16))
            }
            
            // 旋轉控制點（只在編輯模式且元件被選中時顯示）
            if isSelected && viewState.isEditMode {
                // 旋轉控制點設置
                let controlPointRadius: CGFloat = 10
                let controlPointDistance = max(width, height) / 2 + 15
                
                // 計算控制點的位置（考慮PAD的旋轉角度）
                let controlAngle = (pad.rotatedAngle - 45) * .pi / 180
                let controlX = centerPosition.x + controlPointDistance * cos(controlAngle)
                let controlY = centerPosition.y + controlPointDistance * sin(controlAngle)
                
                // 繪製旋轉控制點
                ZStack {
                    // 外圈
                    Circle()
                        .stroke(Color.orange, lineWidth: 2)
                        .frame(width: controlPointRadius * 2, height: controlPointRadius * 2)
                    
                    // 內圈
                    Circle()
                        .fill(Color.white)
                        .frame(width: controlPointRadius * 1.2, height: controlPointRadius * 1.2)
                    
                    // 旋轉圖標
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 8))
                        .foregroundColor(.orange)
                }
                .position(x: controlX, y: controlY)
                // 添加拖動手勢
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { value in
                            // 設置拖動狀態
                            isDraggingRotationHandle = true
                            
                            // 獲取中心點和當前拖動點
                            let center = centerPosition
                            let dragPoint = value.location
                            
                            // 儲存起始點（如果尚未設置）
                            if rotationStart == nil {
                                rotationStart = dragPoint
                                
                                // 提供輕微觸覺反饋，表示開始旋轉
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }
                            
                            // 計算角度（相對於X軸正方向）
                            let angle = atan2(dragPoint.y - center.y, dragPoint.x - center.x)
                            
                            // 轉換為度數（0-360範圍）
                            var degrees = angle * 180 / .pi
                            degrees = (degrees + 360).truncatingRemainder(dividingBy: 360)
                            
                            // 吸附到最接近的45度增量
                            let snappedAngle = snapToNearestAngle(degrees, snapAngles: snapAngles)
                            
                            // 更新PAD旋轉角度
                            updatePADRotation(padID: pad.id, angle: snappedAngle)
                            
                            // 如果角度跨越了一個吸附點，提供觸覺反饋
                            let previousAngle = pad.rotatedAngle
                            let previousSnapped = snapToNearestAngle(previousAngle, snapAngles: snapAngles)
                            if previousSnapped != snappedAngle {
                                let generator = UIImpactFeedbackGenerator(style: .rigid)
                                generator.impactOccurred(intensity: 0.7)
                            }
                        }
                        .onEnded { _ in
                            // 重置狀態
                            isDraggingRotationHandle = false
                            rotationStart = nil
                            
                            // 提供觸覺反饋表示旋轉結束
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            
                            // 記錄歷史，以便支援撤銷/重做
                            layoutManager.recordHistory()
                        }
                )
                
                // 可選：旋轉指示線
                if isDraggingRotationHandle {
                    // 繪製從中心到控制點的線
                    Path { path in
                        path.move(to: centerPosition)
                        path.addLine(to: CGPoint(x: controlX, y: controlY))
                    }
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 1, dash: [4, 2]))
                    
                    // 繪製45度增量的參考線
                    ForEach(snapAngles, id: \.self) { angle in
                        Path { path in
                            path.move(to: centerPosition)
                            
                            // 計算角度線終點
                            let lineLength = controlPointDistance * 0.8
                            let angleRadians = angle * .pi / 180
                            let endX = centerPosition.x + lineLength * cos(angleRadians)
                            let endY = centerPosition.y + lineLength * sin(angleRadians)
                            
                            path.addLine(to: CGPoint(x: endX, y: endY))
                        }
                        .stroke(Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                    }
                }
            }
            
            // 顯示角度指示器（當正在旋轉時）
            if isDraggingRotationHandle {
                // 顯示當前吸附角度值
                Text("\(Int(snapToNearestAngle(pad.rotatedAngle, snapAngles: snapAngles)))°")
                    .font(.system(size: 14, weight: .bold))
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.black.opacity(0.7))
                    )
                    .foregroundColor(.white)
                    .position(CGPoint(x: centerPosition.x, y: centerPosition.y - height / 2 - 25))
                    .transition(.opacity)
            }
        }
    }
    
    // 將角度吸附到最接近的45度增量
    private func snapToNearestAngle(_ angle: Double, snapAngles: [Double]) -> Double {
        // 找出最接近的吸附角度
        var closestAngle = snapAngles[0]
        var minDifference = 360.0
        
        for snapAngle in snapAngles {
            // 計算角度差距（考慮循環）
            let rawDiff = abs(angle - snapAngle)
            let diff = min(rawDiff, 360 - rawDiff)
            
            if diff < minDifference {
                minDifference = diff
                closestAngle = snapAngle
            }
        }
        
        // 如果角度接近360度，設為0度
        if closestAngle == 315 && angle > 337.5 {
            return 0
        }
        
        return closestAngle
    }
    
    // 更新PAD旋轉角度
    private func updatePADRotation(padID: UUID, angle: Double) {
        guard var pad = layoutManager.pads[padID] else { return }
        
        // 更新旋轉角度
        pad.rotatedAngle = angle
        layoutManager.updatePAD(pad)
    }
}
