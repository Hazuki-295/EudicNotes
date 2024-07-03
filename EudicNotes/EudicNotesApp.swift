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
                .frame(width: 680, height: 780)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {} // Disable new window
        }
    }
}
