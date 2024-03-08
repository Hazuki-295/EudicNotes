//
//  ContentView.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/3/6.
//

import SwiftUI

enum NavigationItem {
    case main
    case options
}

struct ContentView: View {
    @State private var selection: NavigationItem? = .main
    
    var body: some View {
        NavigationSplitView {
            // Sidebar content
            List(selection: $selection) {
                NavigationLink(value: NavigationItem.main) {
                    Label("Main", systemImage: selection == .main ? "house.fill" : "house")
                }
                
                NavigationLink(value: NavigationItem.options) {
                    Label("Options", systemImage: selection == .options ? "gearshape.fill" : "gearshape")
                }
            }
            .listStyle(SidebarListStyle())
        } detail: {
            // Detail content based on selection
            navigationDestination(for: selection)
        }
    }
    
    // Helper function to return the appropriate view based on the current selection
    @ViewBuilder
    private func navigationDestination(for item: NavigationItem?) -> some View {
        switch item {
        case .main:
            MainView()
        case .options:
            OptionsView()
        default:
            Text("Please select an option")
        }
    }
}

#Preview {
    ContentView()
}
