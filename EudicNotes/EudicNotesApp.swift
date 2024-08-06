//
//  EudicNotesApp.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/3/6.
//

import SwiftUI

@main
struct EudicNotesApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light) // Enforce light mode
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {} // Disable new window
        }
    }
}
