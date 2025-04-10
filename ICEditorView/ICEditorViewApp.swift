//
//  ICEditorViewApp.swift
//  ICEditorView
//
//  Created by TimChi on 2025/3/26.
//

import SwiftUI

@main
struct ICEditorViewApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
