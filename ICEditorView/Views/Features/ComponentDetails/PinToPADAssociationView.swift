//
//  PinToPADAssociationView.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/2.
//

import SwiftUI

/// Pin與PAD關聯管理視圖
struct PinToPADAssociationView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - 屬性
    @ObservedObject var layoutManager: ICLayoutManager
    
    // 選擇狀態
    @State private var selectedPinID: UUID?
    @State private var selectedPADID: UUID?
    
    // 過濾與搜尋
    @State private var pinSearchText: String = ""
    @State private var padSearchText: String = ""
    
    // 多選狀態
    @State private var multiSelectMode: Bool = false
    @State private var selectedPinIDs: Set<UUID> = []
    @State private var selectedPADIDs: Set<UUID> = []
    
    // 視圖狀態
    @State private var showSuccessMessage: Bool = false
    @State private var successMessage: String = ""
    @State private var showAssociationDetails: Bool = false
    
    // 排序選項
    @State private var pinSortOption: SortOption = .name
    @State private var padSortOption: SortOption = .name
    
    // MARK: - 計算屬性
    
    // 根據搜尋和排序過濾Pin列表
    private var filteredPins: [ModelPin] {
        var result = layoutManager.pins.values.map { $0 }
        
        // 搜尋過濾
        if !pinSearchText.isEmpty {
            result = result.filter { pin in
                pin.name.localizedCaseInsensitiveContains(pinSearchText) ||
                pin.pinName.localizedCaseInsensitiveContains(pinSearchText) ||
                String(pin.pinIndex).contains(pinSearchText)
            }
        }
        
        // 排序
        switch pinSortOption {
        case .name:
            result.sort { $0.name < $1.name }
        case .index:
            result.sort { $0.pinIndex < $1.pinIndex }
        case .associations:
            result.sort { $0.padIDs.count > $1.padIDs.count }
        }
        
        return result
    }
    
    // 根據搜尋和排序過濾PAD列表
    private var filteredPADs: [ModelPAD] {
        var result = layoutManager.pads.values.map { $0 }
        
        // 搜尋過濾
        if !padSearchText.isEmpty {
            result = result.filter { pad in
                pad.name.localizedCaseInsensitiveContains(padSearchText) ||
                pad.padPinName.localizedCaseInsensitiveContains(padSearchText)
            }
        }
        
        // 排序
        switch padSortOption {
        case .name:
            result.sort { $0.name < $1.name }
        case .index:
            result.sort { $0.staggerIndex < $1.staggerIndex }
        case .associations:
            result.sort { $0.pinIDs.count > $1.pinIDs.count }
        }
        
        return result
    }
    
    // 獲取選中的Pin關聯的PAD
    private var associatedPADsForSelectedPin: [ModelPAD]? {
        guard let pinID = selectedPinID, let pin = layoutManager.pins[pinID] else {
            return nil
        }
        
        return pin.padIDs.compactMap { layoutManager.pads[$0] }
    }
    
    // 獲取選中的PAD關聯的Pin
    private var associatedPinsForSelectedPAD: [ModelPin]? {
        guard let padID = selectedPADID, let pad = layoutManager.pads[padID] else {
            return nil
        }
        
        return pad.pinIDs.compactMap { layoutManager.pins[$0] }
    }
    
    // MARK: - 主視圖
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 標題與模式切換
                HStack {
                    Text("Pin與PAD關聯管理")
                        .font(.headline)
                        .padding()
                    
                    Spacer()
                    
                    // 多選模式切換
                    Toggle(isOn: $multiSelectMode) {
                        Text("多選模式")
                            .font(.subheadline)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .padding(.trailing)
                }
                .background(Color(UIColor.secondarySystemBackground))
                
                // 內容區域
                if multiSelectMode {
                    multiSelectModeView
                } else {
                    singleSelectModeView
                }
                
                // 底部操作按鈕
                bottomActionButtons
            }
            .navigationBarHidden(true)
            .alert(isPresented: $showSuccessMessage) {
                Alert(
                    title: Text("操作完成"),
                    message: Text(successMessage),
                    dismissButton: .default(Text("確定"))
                )
            }
            .sheet(isPresented: $showAssociationDetails) {
                associationDetailsSheet
            }
        }
    }
    
    // MARK: - 單選模式視圖
    
    private var singleSelectModeView: some View {
        HStack(spacing: 0) {
            // 左側 Pin 選擇區
            VStack {
                // 搜尋與排序
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("搜尋Pin...", text: $pinSearchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Menu {
                        Button(action: { pinSortOption = .name }) {
                            Label("按名稱排序", systemImage: "textformat")
                        }
                        Button(action: { pinSortOption = .index }) {
                            Label("按索引排序", systemImage: "number")
                        }
                        Button(action: { pinSortOption = .associations }) {
                            Label("按關聯數排序", systemImage: "link")
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .padding(8)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                    }
                }
                .padding([.horizontal, .top])
                
                // Pin列表
                List {
                    ForEach(filteredPins, id: \.id) { pin in
                        PinListItemView(
                            pin: pin,
                            isSelected: pin.id == selectedPinID,
                            associationCount: pin.padIDs.count
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectPin(pin.id)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .background(Color(UIColor.systemBackground))
            
            // 中間按鈕區
            VStack(spacing: 15) {
                // 關聯按鈕
                Button(action: {
                    createAssociation()
                }) {
                    VStack {
                        Image(systemName: "link")
                            .font(.system(size: 20))
                        Text("建立\n關聯")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    .frame(width: 60, height: 60)
                    .background(
                        canCreateAssociation ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1)
                    )
                    .foregroundColor(canCreateAssociation ? .blue : .gray)
                    .cornerRadius(10)
                }
                .disabled(!canCreateAssociation)
                
                // 解除關聯按鈕
                Button(action: {
                    removeAssociation()
                }) {
                    VStack {
                        Image(systemName: "link.badge.minus")
                            .font(.system(size: 20))
                        Text("解除\n關聯")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    .frame(width: 60, height: 60)
                    .background(
                        canRemoveAssociation ? Color.red.opacity(0.2) : Color.gray.opacity(0.1)
                    )
                    .foregroundColor(canRemoveAssociation ? .red : .gray)
                    .cornerRadius(10)
                }
                .disabled(!canRemoveAssociation)
                
                // 檢視關聯按鈕
                Button(action: {
                    showAssociationDetails = true
                }) {
                    VStack {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 20))
                        Text("檢視\n關聯")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    .frame(width: 60, height: 60)
                    .background(
                        canViewAssociations ? Color.green.opacity(0.2) : Color.gray.opacity(0.1)
                    )
                    .foregroundColor(canViewAssociations ? .green : .gray)
                    .cornerRadius(10)
                }
                .disabled(!canViewAssociations)
            }
            .padding(.vertical)
            .background(Color(UIColor.secondarySystemBackground))
            
            // 右側 PAD 選擇區
            VStack {
                // 搜尋與排序
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("搜尋PAD...", text: $padSearchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Menu {
                        Button(action: { padSortOption = .name }) {
                            Label("按名稱排序", systemImage: "textformat")
                        }
                        Button(action: { padSortOption = .index }) {
                            Label("按索引排序", systemImage: "number")
                        }
                        Button(action: { padSortOption = .associations }) {
                            Label("按關聯數排序", systemImage: "link")
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .padding(8)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                    }
                }
                .padding([.horizontal, .top])
                
                // PAD列表
                List {
                    ForEach(filteredPADs, id: \.id) { pad in
                        PADListItemView(
                            pad: pad,
                            isSelected: pad.id == selectedPADID,
                            associationCount: pad.pinIDs.count
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectPAD(pad.id)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .background(Color(UIColor.systemBackground))
        }
    }
    
    // MARK: - 多選模式視圖
    
    private var multiSelectModeView: some View {
        HStack(spacing: 0) {
            // 左側 Pin 多選區
            VStack {
                // 搜尋與排序
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("搜尋Pin...", text: $pinSearchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        // 切換全選/取消全選
                        if selectedPinIDs.count == filteredPins.count {
                            selectedPinIDs.removeAll()
                        } else {
                            selectedPinIDs = Set(filteredPins.map { $0.id })
                        }
                    }) {
                        Image(systemName: selectedPinIDs.count == filteredPins.count ? "checkmark.circle.fill" : "circle")
                            .padding(8)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                    }
                }
                .padding([.horizontal, .top])
                
                // Pin多選列表
                List {
                    ForEach(filteredPins, id: \.id) { pin in
                        PinListItemView(
                            pin: pin,
                            isSelected: selectedPinIDs.contains(pin.id),
                            associationCount: pin.padIDs.count,
                            selectionStyle: .checkbox
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // 切換選中狀態
                            if selectedPinIDs.contains(pin.id) {
                                selectedPinIDs.remove(pin.id)
                            } else {
                                selectedPinIDs.insert(pin.id)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                
                // 選中計數
                Text("已選擇 \(selectedPinIDs.count) 個Pin")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .background(Color(UIColor.systemBackground))
            
            // 中間按鈕區
            VStack(spacing: 15) {
                // 批量關聯按鈕
                Button(action: {
                    batchCreateAssociations()
                }) {
                    VStack {
                        Image(systemName: "link.badge.plus")
                            .font(.system(size: 20))
                        Text("批量\n建立\n關聯")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    .frame(width: 60, height: 70)
                    .background(canBatchCreateAssociations ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                    .foregroundColor(canBatchCreateAssociations ? .blue : .gray)
                    .cornerRadius(10)
                }
                .disabled(!canBatchCreateAssociations)
                
                // 批量解除關聯按鈕
                Button(action: {
                    batchRemoveAssociations()
                }) {
                    VStack {
                        Image(systemName: "trash")
                            .font(.system(size: 20))
                        Text("批量\n解除\n關聯")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    .frame(width: 60, height: 70)
                    .background(canBatchRemoveAssociations ? Color.red.opacity(0.2) : Color.gray.opacity(0.1))
                    .foregroundColor(canBatchRemoveAssociations ? .red : .gray)
                    .cornerRadius(10)
                }
                .disabled(!canBatchRemoveAssociations)
                
                // 清空選擇按鈕
                Button(action: {
                    selectedPinIDs.removeAll()
                    selectedPADIDs.removeAll()
                }) {
                    VStack {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 20))
                        Text("清空\n選擇")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    .frame(width: 60, height: 70)
                    .background(Color.gray.opacity(0.1))
                    .foregroundColor(.gray)
                    .cornerRadius(10)
                }
            }
            .padding(.vertical)
            .background(Color(UIColor.secondarySystemBackground))
            
            // 右側 PAD 多選區
            VStack {
                // 搜尋與排序
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("搜尋PAD...", text: $padSearchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        // 切換全選/取消全選
                        if selectedPADIDs.count == filteredPADs.count {
                            selectedPADIDs.removeAll()
                        } else {
                            selectedPADIDs = Set(filteredPADs.map { $0.id })
                        }
                    }) {
                        Image(systemName: selectedPADIDs.count == filteredPADs.count ? "checkmark.circle.fill" : "circle")
                            .padding(8)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                    }
                }
                .padding([.horizontal, .top])
                
                // PAD多選列表
                List {
                    ForEach(filteredPADs, id: \.id) { pad in
                        PADListItemView(
                            pad: pad,
                            isSelected: selectedPADIDs.contains(pad.id),
                            associationCount: pad.pinIDs.count,
                            selectionStyle: .checkbox
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // 切換選中狀態
                            if selectedPADIDs.contains(pad.id) {
                                selectedPADIDs.remove(pad.id)
                            } else {
                                selectedPADIDs.insert(pad.id)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                
                // 選中計數
                Text("已選擇 \(selectedPADIDs.count) 個PAD")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .background(Color(UIColor.systemBackground))
        }
    }
    
    // MARK: - 底部操作按鈕
    
    private var bottomActionButtons: some View {
        HStack {
            // 顯示當前關聯統計
            VStack(alignment: .leading, spacing: 4) {
                Text("Pin總數: \(layoutManager.pins.count)")
                Text("PAD總數: \(layoutManager.pads.count)")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.leading)
            
            Spacer()
            
            // 關閉按鈕
            Button("關閉") {
                dismiss()  // 使用環境變數中的 dismiss 函數
            }
            .padding()
        }
        .padding(.bottom, 8)
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    // MARK: - 關聯詳情表
    
    private var associationDetailsSheet: some View {
        NavigationView {
            VStack {
                if let pinID = selectedPinID, let pin = layoutManager.pins[pinID], !pin.padIDs.isEmpty {
                    // 顯示Pin關聯的PAD列表
                    List {
                        Section(header: Text("Pin: \(pin.name) (\(pin.pinIndex)) 的關聯")) {
                            ForEach(pin.padIDs, id: \.self) { padID in
                                if let pad = layoutManager.pads[padID] {
                                    HStack {
                                        Text(pad.name)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            layoutManager.dissociatePinFromPAD(pinID: pinID, padID: padID)
                                            // 如果移除後沒有關聯了，關閉詳情視圖
                                            if layoutManager.pins[pinID]?.padIDs.isEmpty ?? true {
                                                showAssociationDetails = false
                                            }
                                        }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else if let padID = selectedPADID, let pad = layoutManager.pads[padID], !pad.pinIDs.isEmpty {
                    // 顯示PAD關聯的Pin列表
                    List {
                        Section(header: Text("PAD: \(pad.name) 的關聯")) {
                            ForEach(pad.pinIDs, id: \.self) { pinID in
                                if let pin = layoutManager.pins[pinID] {
                                    HStack {
                                        Text("Pin-\(pin.pinIndex): \(pin.name)")
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            layoutManager.dissociatePinFromPAD(pinID: pinID, padID: padID)
                                            // 如果移除後沒有關聯了，關閉詳情視圖
                                            if layoutManager.pads[padID]?.pinIDs.isEmpty ?? true {
                                                showAssociationDetails = false
                                            }
                                        }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    // 無選擇或無關聯時顯示的內容
                    VStack {
                        Image(systemName: "link.slash")
                            .font(.largeTitle)
                            .padding()
                        
                        Text("無關聯數據")
                            .font(.headline)
                        
                        Text("請先選擇一個有關聯的Pin或PAD")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(UIColor.systemBackground))
                }
            }
            .navigationTitle("關聯詳情")
            .navigationBarItems(trailing: Button("關閉") {
                showAssociationDetails = false
            })
        }
    }
    
    // MARK: - 操作按鈕啟用條件
    
    // 單選模式 - 是否可以建立關聯
    private var canCreateAssociation: Bool {
        guard let pinID = selectedPinID, let padID = selectedPADID else {
            return false
        }
        
        // 確保Pin和PAD都存在
        guard let pin = layoutManager.pins[pinID], let pad = layoutManager.pads[padID] else {
            return false
        }
        
        // 檢查是否已經有關聯
        return !pin.padIDs.contains(padID)
    }
    
    // 單選模式 - 是否可以解除關聯
    private var canRemoveAssociation: Bool {
        guard let pinID = selectedPinID, let padID = selectedPADID else {
            return false
        }
        
        // 確保Pin和PAD都存在
        guard let pin = layoutManager.pins[pinID], let pad = layoutManager.pads[padID] else {
            return false
        }
        
        // 檢查是否已經有關聯
        return pin.padIDs.contains(padID)
    }
    
    // 單選模式 - 是否可以查看關聯
    private var canViewAssociations: Bool {
        if let pinID = selectedPinID, let pin = layoutManager.pins[pinID], !pin.padIDs.isEmpty {
            return true
        }
        
        if let padID = selectedPADID, let pad = layoutManager.pads[padID], !pad.pinIDs.isEmpty {
            return true
        }
        
        return false
    }
    
    // 多選模式 - 是否可以批量建立關聯
    private var canBatchCreateAssociations: Bool {
        !selectedPinIDs.isEmpty && !selectedPADIDs.isEmpty
    }
    
    // 多選模式 - 是否可以批量解除關聯
    private var canBatchRemoveAssociations: Bool {
        !selectedPinIDs.isEmpty && !selectedPADIDs.isEmpty
    }
    
    // MARK: - 操作方法
    
    // 選擇Pin
    private func selectPin(_ pinID: UUID) {
        // 如果已選擇，則取消選擇
        if selectedPinID == pinID {
            selectedPinID = nil
        } else {
            selectedPinID = pinID
        }
    }
    
    // 選擇PAD
    private func selectPAD(_ padID: UUID) {
        // 如果已選擇，則取消選擇
        if selectedPADID == padID {
            selectedPADID = nil
        } else {
            selectedPADID = padID
        }
    }
    
    // 單選模式 - 建立關聯
    private func createAssociation() {
        guard let pinID = selectedPinID, let padID = selectedPADID else {
            return
        }
        
        let success = layoutManager.associatePinToPAD(pinID: pinID, padID: padID)
        
        if success {
            // 顯示成功訊息
            successMessage = "已成功建立關聯"
            showSuccessMessage = true
        }
    }
    
    // 單選模式 - 解除關聯
    private func removeAssociation() {
        guard let pinID = selectedPinID, let padID = selectedPADID else {
            return
        }
        
        let success = layoutManager.dissociatePinFromPAD(pinID: pinID, padID: padID)
        
        if success {
            // 顯示成功訊息
            successMessage = "已成功解除關聯"
            showSuccessMessage = true
        }
    }
    
    // 多選模式 - 批量建立關聯
    private func batchCreateAssociations() {
        let pinIDsArray = Array(selectedPinIDs)
        let padIDsArray = Array(selectedPADIDs)
        
        // 計算總關聯數
        let totalAssociations = pinIDsArray.count * padIDsArray.count
        
        // 創建批量關聯
        var successCount = 0
        
        for pinID in pinIDsArray {
            for padID in padIDsArray {
                if layoutManager.associatePinToPAD(pinID: pinID, padID: padID) {
                    successCount += 1
                }
            }
        }
        
        // 顯示成功訊息
        successMessage = "已成功建立 \(successCount)/\(totalAssociations) 個關聯"
        showSuccessMessage = true
        
        // 清空選擇
        selectedPinIDs.removeAll()
        selectedPADIDs.removeAll()
    }
    
    // 多選模式 - 批量解除關聯
    private func batchRemoveAssociations() {
        let pinIDsArray = Array(selectedPinIDs)
        let padIDsArray = Array(selectedPADIDs)
        
        // 計算總關聯數
        let totalAssociations = pinIDsArray.count * padIDsArray.count
        
        // 解除批量關聯
        var successCount = 0
        
        for pinID in pinIDsArray {
            for padID in padIDsArray {
                if layoutManager.dissociatePinFromPAD(pinID: pinID, padID: padID) {
                    successCount += 1
                }
            }
        }
        
        // 顯示成功訊息
        successMessage = "已成功解除 \(successCount)/\(totalAssociations) 個關聯"
        showSuccessMessage = true
        
        // 清空選擇
        selectedPinIDs.removeAll()
        selectedPADIDs.removeAll()
    }
}

// MARK: - 輔助視圖

/// Pin列表項目視圖
struct PinListItemView: View {
    enum SelectionStyle {
        case highlight
        case checkbox
    }
    
    let pin: ModelPin
    let isSelected: Bool
    let associationCount: Int
    var selectionStyle: SelectionStyle = .highlight
    
    var body: some View {
        HStack {
            // 選擇指示器
            if selectionStyle == .checkbox {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            
            // Pin資訊
            VStack(alignment: .leading) {
                Text(pin.name)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                HStack {
                    Text("索引: \(pin.pinIndex)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // 關聯計數
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(.caption)
                        Text("\(associationCount)")
                            .font(.caption)
                    }
                    .foregroundColor(associationCount > 0 ? .blue : .secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .background(selectionStyle == .highlight && isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(4)
    }
}

/// PAD列表項目視圖
struct PADListItemView: View {
    enum SelectionStyle {
        case highlight
        case checkbox
    }
    
    let pad: ModelPAD
    let isSelected: Bool
    let associationCount: Int
    var selectionStyle: SelectionStyle = .highlight
    
    var body: some View {
        HStack {
            // 選擇指示器
            if selectionStyle == .checkbox {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            
            // PAD資訊
            VStack(alignment: .leading) {
                Text(pad.name)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                HStack {
                    Text(pad.padPinName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // 關聯計數
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(.caption)
                        Text("\(associationCount)")
                            .font(.caption)
                    }
                    .foregroundColor(associationCount > 0 ? .green : .secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .background(selectionStyle == .highlight && isSelected ? Color.green.opacity(0.1) : Color.clear)
        .cornerRadius(4)
    }
}

// MARK: - 輔助類型

/// 排序選項
enum SortOption {
    case name
    case index
    case associations
}
