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
            // Source
            HStack {
                Image(systemName: "text.book.closed")
                ComboBox(text: $sharedNoteData.source, options: sourceHistory.history.sorted(), label: "Source")
                    .onSubmit { sourceHistory.addToHistory(newEntry: sharedNoteData.source) }
            }
            
            // Original Text
            HStack {
                VStack {
                    HStack {
                        Image(systemName: "book")
                        Text("Original Text:")
                    }
                    Button(action: { sharedNoteData.clearLabels(); }){
                        HStack {
                            Image(systemName: "eraser.line.dashed")
                            Text("Clear")
                        }
                    }
                }
                CustomTextEditor(text: $sharedNoteData.originalText)
            }
            .frame(height: 120)
            
            // Word or Phrase
            HStack {
                Image(systemName: "highlighter")
                Text("Word / Phrase:")
                TextField("Enter Word or Phrase", text: $sharedNoteData.wordPhrase)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Notes
            HStack {
                Image(systemName: "bookmark")
                Text("Notes:")
                CustomTextEditor(text: $sharedNoteData.notes)
            }
            .frame(height: 120)
            
            // Tags
            HStack {
                Image(systemName: "tag")
                ComboBox(text: $sharedNoteData.tags, options: tagsHistory.history.sorted(), label: "Tags")
                    .onSubmit { tagsHistory.addToHistory(newEntry: sharedNoteData.tags) }
            }
            
            // buttons
            HStack {
                Button(action: { ClipboardManager.copyToClipboard(textToCopy: sharedNoteData.updataHTMLContentWithTemplate()) }) {
                    HStack {
                        Image(systemName: "paintbrush")
                        Text("Generate Notes")
                    }
                }
                Button(action: { ClipboardManager.copyToClipboard(textToCopy: sharedNoteData.noteTemplateHTMLIframe()) }) {
                    HStack {
                        Image(systemName: "list.clipboard")
                        Text("Copy Template HTML")
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
        .frame(width: 680, height: 780)
    }
}

#Preview {
    ContentView()
}
