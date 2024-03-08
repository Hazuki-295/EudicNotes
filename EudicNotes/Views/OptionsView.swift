//
//  OptionsView.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/3/7.
//

import SwiftUI

enum Tabs {
    case trimPassage
    case combineNotes
}

struct OptionsView: View {
    @State private var selectedTab: Tabs = .trimPassage
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TrimPassageView()
                .tabItem {
                    Text("Trim Passage")
                }
                .tag(Tabs.trimPassage)
            
            CombineNotesView()
                .tabItem {
                    Text("Combine Notes")
                }
                .tag(Tabs.combineNotes)
        }
        .padding()
    }
}

#Preview {
    OptionsView()
}
