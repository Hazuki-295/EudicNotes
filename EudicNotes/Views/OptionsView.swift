//
//  OptionsView.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/3/7.
//

import SwiftUI

struct OptionsView: View {
    private enum Tabs {
        case combineNotes, trimPassage
    }
    
    @State private var selectedTab: Tabs = .combineNotes
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CombineNotesView()
                .tabItem { Text("Combine Notes") }
                .tag(Tabs.combineNotes)
            
            TrimPassageView()
                .tabItem { Text("Trim Passage") }
                .tag(Tabs.trimPassage)
        }
        .padding()
        .frame(width: 750, height: 850)
    }
}

#Preview {
    OptionsView()
}
