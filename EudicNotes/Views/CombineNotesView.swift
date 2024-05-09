//
//  CombineNotesView.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/3/8.
//

import SwiftUI

struct SingleNotesView: View {
    private let label: String
    private let labelColor: Color
    private let systemImage: String
    
    @EnvironmentObject var sharedNoteData: NoteData
    @StateObject var noteData: NoteData
    private let mainNoteData: Bool
    
    @State private var showTextEditor = false
    
    init (label: String, labelColor: Color, systemImage: String, noteData: NoteData, mainNoteData: Bool = false) {
        self.label = label
        self.labelColor = labelColor
        self.systemImage = systemImage
        self._noteData = StateObject(wrappedValue: noteData)
        self.mainNoteData = mainNoteData
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Label(label, systemImage: systemImage).foregroundColor(labelColor)
            
            HStack {
                CustomTextEditor(text: $noteData.userInputPlainNote)
                
                ZStack {
                    // visible by default
                    if !showTextEditor {
                        CustomWebView(htmlString: $noteData.userInputRenderedNote)
                    }
                    
                    // hidden by default
                    if showTextEditor {
                        CustomTextEditor(text: $noteData.userInputRenderedNote)
                    }
                }
            }
            
            HStack {
                Button(action: {
                    if let text = ClipboardManager.pasteFromClipboard() {
                        noteData.recognizeNote(plainNote: text)
                        noteData.manualUpdate()
                    }
                }) {
                    Image(systemName: "doc.on.clipboard")
                    Text("Paste")
                }
                if !mainNoteData {
                    Button(action: { noteData.updateWith(noteData: sharedNoteData) }) {
                        Image(systemName: "doc.on.clipboard")
                        Text("Paste From Main")
                    }
                }
                Spacer()
                Button(action: { showTextEditor.toggle() }) {
                    Image(systemName: "switch.2")
                    Text("Switch")
                }
                Button(action: { noteData.clearFields() }) {
                    Image(systemName: "eraser.line.dashed")
                    Text("Clear")
                }
            }
        }
    }
}

struct CombineNotesView: View {
    @StateObject private var noteData1 = NoteData()
    @StateObject private var noteData2 = NoteData()
    @StateObject private var noteData3 = NoteData()
    @StateObject private var noteData4 = NoteData()
    
    @State private var combinedNotes: String = ""
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 15) {
                    SingleNotesView(label: "First Notes", labelColor: .brown, systemImage: "note.text", noteData: noteData1)
                    SingleNotesView(label: "Second Notes", labelColor: .purple, systemImage: "2.square", noteData: noteData2)
                    SingleNotesView(label: "Third Notes", labelColor: .blue, systemImage: "3.square", noteData: noteData3)
                    SingleNotesView(label: "Fourth Notes", labelColor: .red, systemImage: "4.square", noteData: noteData4)
                }
                .padding(.top, 5)
                
                // clear all
                Button(action: {
                    noteData1.clearFields()
                    noteData2.clearFields()
                    noteData3.clearFields()
                    noteData4.clearFields()
                }) {
                    Image(systemName: "eraser.line.dashed")
                    Text("Clear All")
                }
                
                // combine notes
                HStack {
                    Button(action: {
                        var noteComponents = retrieveNotes()
                        while noteComponents.count < 4 {
                            noteComponents.append("")
                        }
                        (noteData1.userInputPlainNote, noteData2.userInputPlainNote, noteData3.userInputPlainNote, noteData4.userInputPlainNote) = (noteComponents[0], noteComponents[1], noteComponents[2], noteComponents[3])
                    }) {
                        Image(systemName: "list.clipboard").foregroundColor(.purple)
                        Text("Retrieve Clipboard").foregroundColor(.purple)
                    }
                    Button(action: {
                        let separator = "\n" + "<hr style=\"border: none; height: 2px; background-color: #949494; margin: 20px 0;\">"
                        let notes = [noteData1.userInputRenderedNote, noteData2.userInputRenderedNote, noteData3.userInputRenderedNote, noteData4.userInputRenderedNote]
                        combinedNotes = notes.filter { !$0.isEmpty }.joined(separator: separator)
                        ClipboardManager.copyToClipboard(textToCopy: combinedNotes)
                    }) {
                        Image(systemName: "book").foregroundColor(.indigo)
                        Text("Combine Notes").foregroundColor(.indigo)
                    }
                }
                .position(x: geometry.size.width / 2 - 20, y: geometry.safeAreaInsets.top + 10)
            }
            .padding(.top, 5)
            .padding(.bottom)
            .padding(.leading)
            .padding(.trailing)
        }
    }
    
    private func retrieveNotes() -> [String] {
        // retrieve clipboard
        let combinedNotes = ClipboardManager.pasteFromClipboard() ?? ""
        
        let pattern = #"(\[Source\][\s\S]+?)(?=\[Source\]|$)"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(combinedNotes.startIndex..., in: combinedNotes)
        let matches = regex.matches(in: combinedNotes, options: [], range: range)
        
        // Convert each match into a Swift String and collect them into an array
        let noteComponents = matches.map {
            String(combinedNotes[Range($0.range, in: combinedNotes)!]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return noteComponents
    }
}

#Preview {
    OptionsView()
}
