//
//  CombineNotesView.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/3/8.
//

import SwiftUI
import WebKit

struct CombineNotesView: View {
    @StateObject private var combinedNoteData = NoteData(useUserDefaults: false)
    @StateObject private var singleNoteData = NoteData(useUserDefaults: false, histories: [])
    
    var body: some View {
        VStack(alignment: .center) {
            HStack {
                Button(action: {}) {
                    Image(systemName: "list.clipboard").foregroundColor(.purple)
                    Text("Retrieve Clipboard").foregroundColor(.purple)
                }
                Button(action: {}) {
                    Image(systemName: "book").foregroundColor(.indigo)
                    Text("Combine Notes").foregroundColor(.indigo)
                }
            }
            
            SingleNoteView(noteData: combinedNoteData, combinedNoteData: true, label: "Combined Notes", labelColor: .corenlp)
                .onReceive(combinedNoteData.historyManager.$histories) { histories in
                    if singleNoteData.historyManager.histories != histories {
                        singleNoteData.historyManager.histories = histories
                        singleNoteData.historyManager.latestHistoryIndex = histories.count - 1
                        singleNoteData.historyIndex = 0
                        singleNoteData.loadFromHistory()
                    }
                    combinedNoteData.noteHTMLContent = NoteData.constructNoteTemplateHTML(dictionaries: histories)
                }
            SingleNoteView(noteData: singleNoteData, enableHistory: true, label: "Single NoteData Preview", labelColor: .oaldBlue)
                .onReceive(singleNoteData.historyManager.$histories) { histories in
                    if combinedNoteData.historyManager.histories != histories {
                        combinedNoteData.historyManager.histories = histories
                    }
                }
                .frame(height: 350)
            
        }
        .padding(.top, 5)
        .padding(.bottom)
        .padding(.leading)
        .padding(.trailing)
    }
}

struct CombineNotesView_Previews: PreviewProvider {
    static var previews: some View {
        previewOptionsView()
    }
}
