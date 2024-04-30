//
//  CombineNotesView.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/3/8.
//

import SwiftUI

struct SingleNotesView: View {
    let label: String
    let labelColor: Color
    let systemImage: String
    
    @State var source = ""
    @State var originalText = ""
    @State var notes = ""
    @State var tags = ""
    
    @Binding var noteText: String
    @Binding var renderedNote: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Label(label, systemImage: systemImage).foregroundColor(labelColor)
            
            HStack {
                CustomTextEditor(text: $noteText, minWidth: 300)
                CustomTextEditor(text: $renderedNote, minWidth: 300)
                    .onChange(of: noteText) { [noteText] in
                        if noteText != "" {
                            Utils.recognizeMessage(in: noteText, source: &source, originalText: &originalText, notes: &notes, tags: &tags)
                            renderedNote = Utils.generateMessage(source: source, originalText: originalText, notes: notes, tags: tags)
                        } else {
                            renderedNote = ""
                        }
                    }
            }
            HStack {
                Button(action: {if let text = ClipboardManager.pasteFromClipboard() {noteText = text}}) {
                    Image(systemName: "doc.on.clipboard")
                    Text("Paste")
                }
                Spacer()
                Button(action: { noteText = "" }) {
                    Image(systemName: "eraser.line.dashed")
                    Text("Clear")
                }
            }
        }
    }
}

struct CombineNotesView: View {
    @State private var note1: String = ""
    @State private var note2: String = ""
    @State private var note3: String = ""
    @State private var note4: String = ""
    
    @State private var renderedNote1: String = ""
    @State private var renderedNote2: String = ""
    @State private var renderedNote3: String = ""
    @State private var renderedNote4: String = ""
    
    @State private var combinedNotes: String = ""
    
    private let separator:String = "\n<hr style=\"border: none; height: 2px; background-color: #949494; margin: 20px 0; margin-left: 0; margin-right: 0;\">"
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 15) {
                    SingleNotesView(label: "First Notes", labelColor: .brown, systemImage: "note.text", noteText: $note1, renderedNote: $renderedNote1)
                    SingleNotesView(label: "Second Notes", labelColor: .purple, systemImage: "2.square", noteText: $note2, renderedNote: $renderedNote2)
                    SingleNotesView(label: "Third Notes", labelColor: .blue, systemImage: "3.square", noteText: $note3, renderedNote: $renderedNote3)
                    SingleNotesView(label: "Fourth Notes", labelColor: .red, systemImage: "4.square", noteText: $note4, renderedNote: $renderedNote4)
                }
                .padding(.top, 5)
                
                // clear all
                Button(action: {
                    note1 = ""
                    note2 = ""
                    note3 = ""
                    note4 = ""
                }) {
                    Image(systemName: "eraser.line.dashed")
                    Text("Clear All")
                }
                
                // combine notes
                HStack {
                    Button(action: {
                        let notes = [renderedNote1, renderedNote2, renderedNote3, renderedNote4]
                        combinedNotes = notes.filter { !$0.isEmpty }.joined(separator: separator)
                        ClipboardManager.copyToClipboard(textToCopy: combinedNotes)
                    }) {
                        Image(systemName: "book").foregroundColor(.indigo)
                        Text("Combine Notes").foregroundColor(.indigo)
                    }
                    
                    Button(action: {
                        var noteComponents = retrieveNotes()
                        
                        while noteComponents.count < 4 {
                            noteComponents.append("")
                        }
                        
                        note1 = noteComponents[0]
                        note2 = noteComponents[1]
                        note3 = noteComponents[2]
                        note4 = noteComponents[3]
                    }) {
                        Image(systemName: "list.clipboard").foregroundColor(.purple)
                        Text("Retrieve Clipboard").foregroundColor(.purple)
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
    
    func retrieveNotes() -> [String] {
        // retrieve clipboard
        let combinedNotes = ClipboardManager.pasteFromClipboard() ?? ""
        
        let pattern = "(\\[Source\\][\\s\\S]*?)(?=\\[Source\\]|$)"
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
