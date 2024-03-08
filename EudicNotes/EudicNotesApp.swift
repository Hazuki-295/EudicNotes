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
                .frame(minWidth: 620, minHeight: 840)
        }
        .windowResizability(.contentSize)
    }
}
