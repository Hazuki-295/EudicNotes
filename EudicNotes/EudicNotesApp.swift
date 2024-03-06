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
                .frame(minWidth: 600, idealWidth: 600, maxWidth: 650,
                       minHeight: 650, idealHeight: 650, maxHeight: 800)
        }
        .windowResizability(.contentSize)
    }
}
