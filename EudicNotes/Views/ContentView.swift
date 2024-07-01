//
//  ContentView.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/3/6.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var sourceHistory = InputHistoryViewModel(variableName: "source")
    @StateObject private var tagsHistory = InputHistoryViewModel(variableName: "tags")
    
    @StateObject private var sharedNoteData = NoteData() // shared MainView NoteData
    private let optionsWindowController = OptionsWindowController()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Source
            HStack {
                Image(systemName: "text.book.closed")
                ComboBox(text: $sharedNoteData.source, options: sourceHistory.history.sorted(), label: "Source")
                    .onSubmit {sourceHistory.addToHistory(newEntry: sharedNoteData.source)}
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
            .frame(height: 60)
            
            // Tags
            HStack {
                Image(systemName: "tag")
                ComboBox(text: $sharedNoteData.tags, options: tagsHistory.history.sorted(), label: "Tags")
                    .onSubmit {tagsHistory.addToHistory(newEntry: sharedNoteData.tags)}
            }
            
            // buttons
            HStack {
                Button(action: {
                    sharedNoteData.manualUpdate()
                    ClipboardManager.copyToClipboard(textToCopy: sharedNoteData.userInputRenderedNote)
                }) {
                    HStack {
                        Image(systemName: "paintbrush")
                        Text("Generate Notes")
                    }
                }
                Button(action: { ClipboardManager.copyToClipboard(textToCopy: sharedNoteData.userInputRenderedNote) }) {
                    HStack {
                        Image(systemName: "list.clipboard")
                        Text("Copy Row HTML")
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
            
            SingleNotesView(label: "Combined Notes", labelColor: .purple, systemImage: "note.text", noteData: sharedNoteData, mainNoteData: true)
                .frame(height: 250)
        }
        .padding()
    }
}

extension Character {
    // Check if the character is a CJK character
    var isCJK: Bool {
        return "\u{4E00}" <= self && self <= "\u{9FFF}" || // CJK Unified Ideographs
        "\u{3000}" <= self && self <= "\u{303F}" || // CJK Symbols and Punctuation
        "\u{FF00}" <= self && self <= "\u{FFEF}"    // Full-width ASCII + Half-width Katakana + Full-width symbols and punctuation
    }
}

#Preview {
    ContentView()
}
