//
//  FeedbackToast.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/8.
//


import SwiftUI

struct FeedbackToast: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            )
            .foregroundColor(.primary)
            .transition(.opacity)
    }
}
