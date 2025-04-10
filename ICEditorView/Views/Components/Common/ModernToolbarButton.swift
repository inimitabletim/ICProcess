//
//  ModernToolbarButton.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/9.
//

import SwiftUI

struct ModernToolbarButton: View {
    let icon: String
    let title: String
    var isActive: Bool = false
    var disabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: isActive ? .semibold : .regular))
                    .foregroundColor(buttonColor)
                
                Text(title)
                    .font(.system(size: 12, weight: isActive ? .medium : .regular))
                    .foregroundColor(buttonColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isActive ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1.0)
    }
    
    private var buttonColor: Color {
        if disabled {
            return .gray
        } else if isActive {
            return .accentColor
        } else {
            return .primary
        }
    }
}

