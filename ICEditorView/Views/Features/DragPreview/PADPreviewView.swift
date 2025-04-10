//
//  PADPreviewView.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/9.
//


import SwiftUI

struct PADPreviewView: View {
    let pad: ModelPAD
    let dimension: ModelPADDimension?
    let position: CGPoint
    
    var body: some View {
        let width = CGFloat(dimension?.width ?? 50)
        let height = CGFloat(dimension?.height ?? 30)
        
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.blue.opacity(0.3))
                .frame(width: width, height: height)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.blue, lineWidth: 1.5)
                        .opacity(0.5)
                )
        }
        .rotationEffect(.degrees(pad.rotatedAngle))
        .position(position)
    }
}

