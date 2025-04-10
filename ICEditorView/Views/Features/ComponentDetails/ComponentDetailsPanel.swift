//
//  ComponentDetailsPanel.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/9.
//

import SwiftUI

/// 增強的元件詳細信息面板
struct ComponentDetailsPanel: View {
    let componentID: UUID
    let layoutManager: ICLayoutManager
    let onClose: () -> Void
    let onEdit: () -> Void
    
    @State private var panelPosition: CGPoint
    @State private var dragOffset: CGSize = .zero
    @State private var showingDetails: Bool = true
    @State private var showPositionEditor: Bool = false
    @State private var showRotationEditor: Bool = false
    
    init(
        componentID: UUID,
        layoutManager: ICLayoutManager,
        initialPosition: CGPoint = CGPoint(x: 150, y: 150),
        onClose: @escaping () -> Void,
        onEdit: @escaping () -> Void
    ) {
        self.componentID = componentID
        self.layoutManager = layoutManager
        self._panelPosition = State(initialValue: initialPosition)
        self.onClose = onClose
        self.onEdit = onEdit
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 頂部工具欄
            HStack {
                // 元件類型圖標
                Image(systemName: componentTypeIconName)
                    .font(.title2)
                    .foregroundColor(componentTypeColor)
                    .frame(width: 32)
                
                // 標題區
                VStack(alignment: .leading, spacing: 2) {
                    Text(componentTitle)
                        .font(.headline)
                    
                    Text(componentSubtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 關閉按鈕
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            // 詳細信息顯示/隱藏切換
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingDetails.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(showingDetails ? "隱藏詳細資訊" : "顯示詳細資訊")
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                        
                        Image(systemName: showingDetails ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                Spacer()
            }
            
            // 詳細資訊區域
            if showingDetails {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        // 詳細資訊欄位
                        ForEach(detailItems, id: \.key) { key, value in
                            DetailItem(
                                label: key,
                                value: value,
                                iconName: iconForKey(key)
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .frame(height: 180)
                
                Divider()
            }
            
            // 操作按鈕區域
            HStack(spacing: 12) {
                Button(action: onEdit) {
                    Label("編輯資訊", systemImage: "square.and.pencil")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.accentColor.opacity(0.1))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                if isPad {
                    Button(action: {
                        showPositionEditor = true
                    }) {
                        Label("位置", systemImage: "arrow.up.and.down.and.arrow.left.and.right")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue.opacity(0.1))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        showRotationEditor = true
                    }) {
                        Label("旋轉", systemImage: "arrow.clockwise")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.green.opacity(0.1))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.2), radius: 16)
        )
        .frame(width: 320)
        .position(panelPosition)
        .gesture(
            DragGesture(minimumDistance: 5)
                .onChanged { value in
                    let newPosition = CGPoint(
                        x: panelPosition.x + value.translation.width - dragOffset.width,
                        y: panelPosition.y + value.translation.height - dragOffset.height
                    )
                    panelPosition = newPosition
                    dragOffset = value.translation
                }
                .onEnded { _ in
                    dragOffset = .zero
                }
        )
        .sheet(isPresented: $showPositionEditor) {
            PositionEditorView(
                componentID: componentID,
                layoutManager: layoutManager,
                onClose: { showPositionEditor = false }
            )
        }
        .sheet(isPresented: $showRotationEditor) {
            if isPad, let pad = layoutManager.pads[componentID] {
                RotationEditorView(
                    pad: pad,
                    layoutManager: layoutManager,
                    onClose: { showRotationEditor = false }
                )
            }
        }
    }
    
    // MARK: - 輔助計算屬性
    
    /// 是否為PAD元件
    private var isPad: Bool {
        return layoutManager.pads[componentID] != nil
    }
    
    /// 元件類型圖標名稱
    private var componentTypeIconName: String {
        if layoutManager.pins[componentID] != nil {
            return "circle.fill"
        } else if layoutManager.pads[componentID] != nil {
            return "square.fill"
        }
        return "questionmark.circle.fill"
    }
    
    /// 元件類型顏色
    private var componentTypeColor: Color {
        if layoutManager.pins[componentID] != nil {
            return .blue
        } else if layoutManager.pads[componentID] != nil {
            return .green
        }
        return .gray
    }
    
    /// 元件標題
    private var componentTitle: String {
        if let pin = layoutManager.pins[componentID] {
            return "Pin: \(pin.name)"
        } else if let pad = layoutManager.pads[componentID] {
            return "PAD: \(pad.name)"
        }
        return "未知元件"
    }
    
    /// 元件副標題
    private var componentSubtitle: String {
        if let pin = layoutManager.pins[componentID] {
            return "索引: \(pin.pinIndex) | 類型: \(pin.pinType)"
        } else if let pad = layoutManager.pads[componentID] {
            return pad.isInnerConnectPad ? "內部連接PAD" : "標準PAD"
        }
        return "無詳細資訊"
    }
    
    /// 詳細資訊項目列表
    private var detailItems: [(key: String, value: String)] {
        var items: [(key: String, value: String)] = []
        
        if let pin = layoutManager.pins[componentID] {
            items.append(("索引", "\(pin.pinIndex)"))
            items.append(("名稱", pin.pinName))
            items.append(("類型", "\(pin.pinType)"))
            items.append(("關聯PAD", "\(pin.padIDs.count)"))
            
            // 新增位置資訊
            if let position = pin.getPosition(pads: layoutManager.pads) {
                items.append(("X座標", "\(Int(position.x))"))
                items.append(("Y座標", "\(Int(position.y))"))
            }
        } else if let pad = layoutManager.pads[componentID] {
            items.append(("名稱", pad.name))
            items.append(("X座標", "\(pad.centerLocateX)"))
            items.append(("Y座標", "\(pad.centerLocateY)"))
            items.append(("旋轉角度", String(format: "%.1f°", pad.rotatedAngle)))
            items.append(("寬度", "\(layoutManager.padDimensions[pad.padDimensionID ?? UUID()]?.width ?? 0)"))
            items.append(("高度", "\(layoutManager.padDimensions[pad.padDimensionID ?? UUID()]?.height ?? 0)"))
            items.append(("內部連接", pad.isInnerConnectPad ? "是" : "否"))
            items.append(("錯位排列", pad.isStagger ? "是" : "否"))
            if pad.isStagger {
                items.append(("錯位索引", "\(pad.staggerIndex)"))
            }
            items.append(("關聯Pin", "\(pad.pinIDs.count)"))
        }
        
        return items
    }
    
    /// 為欄位選擇圖標
    private func iconForKey(_ key: String) -> String {
        switch key {
        case "索引":
            return "number"
        case "名稱":
            return "character.textbox"
        case "類型":
            return "tag"
        case "關聯PAD", "關聯Pin":
            return "link"
        case "X座標":
            return "arrow.left.and.right"
        case "Y座標":
            return "arrow.up.and.down"
        case "旋轉角度":
            return "arrow.clockwise"
        case "寬度":
            return "arrow.left.and.right"
        case "高度":
            return "arrow.up.and.down"
        case "內部連接":
            return "arrow.triangle.merge"
        case "錯位排列":
            return "rectangle.grid.2x2"
        case "錯位索引":
            return "arrow.up.right"
        default:
            return "info.circle"
        }
    }
}

/// 詳細資訊項目視圖
struct DetailItem: View {
    let label: String
    let value: String
    let iconName: String
    
    var body: some View {
        HStack(spacing: 12) {
            // 圖標
            Image(systemName: iconName)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 18)
            
            // 標籤
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .leading)
            
            // 值
            Text(value)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

/// 簡單網格視圖
struct Grid: Shape {
    let horizontalCount: Int
    let verticalCount: Int
    let lineWidth: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // 水平線
        let horizontalSpacing = rect.height / CGFloat(verticalCount)
        for i in 0...verticalCount {
            let y = rect.minY + CGFloat(i) * horizontalSpacing
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        
        // 垂直線
        let verticalSpacing = rect.width / CGFloat(horizontalCount)
        for i in 0...horizontalCount {
            let x = rect.minX + CGFloat(i) * verticalSpacing
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }
        
        return path
    }
}
