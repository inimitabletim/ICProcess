//
//  ContentView.swift
//  PinAssignmentViewer
//
//  Created by TimChi on 2025/1/21.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @State private var showLEFEditor = false  // 顯示編輯器狀態
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                Color.white
                VStack {
                    HStack {
                        Spacer()
                        Text("Content View").topBarTextStyle()
                        Spacer()
                    }.topBarBackgroundStyle()
                    
                    Image("AIP_logo_title")
                        .resizable()
                        .scaledToFit()
                    
                    Text("AIP is a company with a professional Electrostatic Discharge(ESD) protection design team dedicated to developing ESD design kits and guidelines for different semiconductor processes. Unlike general industry-specific guidelines, AIP has the unique tools to accurately predict ESD protection capability of product, providing IC design companies with the most comprehensive and cost-effective solution. With years of practice and consulting experience, AIP works with computer-aided design companies and test equipment manufacturers to develop software and hardware verification tools for semiconductor foundries, IC design companies and IP vendors.")
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .font(.custom("Avenir Next Condensed", size: 24))
                        .foregroundColor(.red)
                        .minimumScaleFactor(0.1)
                        .padding()
                    
                    Spacer()
                    
                    NavigationLink {
                        ICLayoutMainView()
                    } label: {
                        Text("Start")
                            .font(.title)
                            .frame(minWidth: geometry.size.width/2)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(lineWidth: 2)
                                    .fill(Color.orange)
                            )
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}

//#Preview {
//    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//}
