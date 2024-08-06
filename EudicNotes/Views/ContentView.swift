//
//  ContentView.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/3/6.
//

import SwiftUI

struct ContentView: View {
    // Create a shared NoteData object to be used by all SingleNoteView
    @StateObject private var sharedNoteData = NoteData()
    
    // History management
    @StateObject private var sourceHistory = InputHistoryViewModel(variableName: "source")
    @StateObject private var tagsHistory = InputHistoryViewModel(variableName: "tags")
    
    // Options window controller
    private let optionsWindowController = OptionsWindowController()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // source
            HStack {
                Image(systemName: "text.book.closed")
                ComboBox(label: "Source", text: $sharedNoteData.source, options: sourceHistory.history.sorted())
            }
            .onSubmit { sourceHistory.addToHistory(newEntry: sharedNoteData.source) }
            
            // original text
            HStack {
                Label("Original Text:", systemImage: "book")
                CustomTextEditor(text: $sharedNoteData.originalText)
            }
            .frame(height: 120)
            
            // word or phrase
            HStack {
                Label("Word / Phrase:", systemImage: "highlighter")
                TextField("Enter Word or Phrase", text: $sharedNoteData.wordPhrase)
                    .textFieldStyle(.roundedBorder)
            }
            
            // notes
            HStack {
                Label("Notes:", systemImage: "bookmark")
                CustomTextEditor(text: $sharedNoteData.notes)
            }
            .frame(height: 120)
            
            // tags
            HStack {
                Image(systemName: "tag")
                ComboBox(label: "Tags", text: $sharedNoteData.tags, options: tagsHistory.history.sorted())
            }
            .onSubmit { tagsHistory.addToHistory(newEntry: sharedNoteData.tags) }
            
            // buttons
            HStack {
                Button(action: { sharedNoteData.updataHTMLContentWithTemplate() }) {
                    HStack {
                        Image(systemName: "paintbrush")
                        Text("Generate Notes")
                    }
                }
                Button(action: { ClipboardManager.copyToClipboard(textToCopy: sharedNoteData.noteTemplateHTML()) }) {
                    HStack {
                        Image(systemName: "list.clipboard")
                        Text("Copy Template HTML")
                    }
                }
                Button(action: { ClipboardManager.copyToClipboard(textToCopy: sharedNoteData.noteJSON()) }) {
                    HStack {
                        Image(systemName: "list.clipboard")
                        Text("Copy JSON")
                    }
                }
                Spacer()
                Button(action: { sharedNoteData.clearFields() }){
                    HStack {
                        Image(systemName: "eraser.line.dashed")
                        Text("Clear")
                    }
                }
                Button(action: { optionsWindowController.openOptionsWindow(sharedNoteData: sharedNoteData) }) {
                    HStack {
                        Image(systemName: "gearshape")
                        Text("Options")
                    }
                }
            }
            
            SingleNoteView(noteData: sharedNoteData, mainNoteData: true, enableHistory: true, label: "Shared NoteData Preview", labelColor: .purple)
        }
        .padding()
        .frame(width: 750, height: 850)
    }
}

#Preview {
    ContentView()
}
