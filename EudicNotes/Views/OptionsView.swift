//
//  OptionsView.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/3/7.
//

import SwiftUI

struct OptionsView: View {
    private enum Tabs {
        case combineNotes, trimPassage, nlpAnnotators
    }
    
    @State private var selectedTab: Tabs = .combineNotes
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NlpAnnotatorsView()
                .tabItem { Text("NLP Annotators") }
                .tag(Tabs.nlpAnnotators)
            
            CombineNotesView()
                .tabItem { Text("Combine Notes") }
                .tag(Tabs.combineNotes)
            
            TrimPassageView()
                .tabItem { Text("Trim Passage") }
                .tag(Tabs.trimPassage)
        }
        .padding()
        .frame(minWidth: 750, maxWidth: 800)
        .frame(minHeight: 850, maxHeight: .infinity)
    }
}

extension PreviewProvider {
    static func previewOptionsView() -> some View {
        OptionsView()
            .environmentObject(NoteData())
    }
}

struct OptionsView_Previews: PreviewProvider {
    static var previews: some View {
        previewOptionsView()
    }
}
