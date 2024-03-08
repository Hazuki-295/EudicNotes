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
    
    private let width: CGFloat = 600
    private let height: CGFloat = 780
    
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
        .frame(minWidth: width, maxWidth: width,
               minHeight: height, maxHeight: height)
        .padding()
    }
}

#Preview {
    OptionsView()
}
