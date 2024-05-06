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
    
    @State private var source = ""
    @State private var originalText = ""
    @State private var notes = ""
    @State private var tags = ""
    
    @Binding var plainNotes: String
    @Binding var renderedNotes: String
    
    @State private var showTextEditor = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Label(label, systemImage: systemImage).foregroundColor(labelColor)
            
            HStack {
                CustomTextEditor(text: $plainNotes)
                
                ZStack {
                    // visible by default
                    if !showTextEditor {
                        CustomWebView(htmlString: $renderedNotes)
                    }
                    
                    // hidden by default
                    if showTextEditor {
                        CustomTextEditor(text: $renderedNotes)
                    }
                }
                .onChange(of: plainNotes) { [plainNotes] in
                    if !plainNotes.isEmpty {
                        MessageUtils.recognizeMessage(in: plainNotes, source: &source, originalText: &originalText, notes: &notes, tags: &tags)
                        renderedNotes = MessageUtils.generateMessage(source: source, originalText: originalText, notes: notes, tags: tags)
                    } else {
                        renderedNotes = ""
                    }
                }
            }
            
            HStack {
                Button(action: {if let text = ClipboardManager.pasteFromClipboard() {plainNotes = text}}) {
                    Image(systemName: "doc.on.clipboard")
                    Text("Paste")
                }
                Spacer()
                Button(action: { showTextEditor.toggle() }) {
                    Image(systemName: "switch.2")
                    Text("Switch")
                }
                Button(action: { (plainNotes, renderedNotes) = ("", "") }) {
                    Image(systemName: "eraser.line.dashed")
                    Text("Clear")
                }
            }
        }
    }
}

struct CombineNotesView: View {
    @State private var plainNotes1: String = ""
    @State private var plainNotes2: String = ""
    @State private var plainNotes3: String = ""
    @State private var plainNotes4: String = ""
    
    @State private var renderedNotes1: String = ""
    @State private var renderedNotes2: String = ""
    @State private var renderedNotes3: String = ""
    @State private var renderedNotes4: String = ""
    
    @State private var combinedNotes: String = ""
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 15) {
                    SingleNotesView(label: "First Notes", labelColor: .brown, systemImage: "note.text", plainNotes: $plainNotes1, renderedNotes: $renderedNotes1)
                    SingleNotesView(label: "Second Notes", labelColor: .purple, systemImage: "2.square", plainNotes: $plainNotes2, renderedNotes: $renderedNotes2)
                    SingleNotesView(label: "Third Notes", labelColor: .blue, systemImage: "3.square", plainNotes: $plainNotes3, renderedNotes: $renderedNotes3)
                    SingleNotesView(label: "Fourth Notes", labelColor: .red, systemImage: "4.square", plainNotes: $plainNotes4, renderedNotes: $renderedNotes4)
                }
                .padding(.top, 5)
                
                // clear all
                Button(action: {
                    (plainNotes1, plainNotes2, plainNotes3, plainNotes4) = ("", "", "", "")
                    (renderedNotes1, renderedNotes2, renderedNotes3, renderedNotes4) = ("", "", "", "")
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
                        (plainNotes1, plainNotes2, plainNotes3, plainNotes4) = (noteComponents[0], noteComponents[1], noteComponents[2], noteComponents[3])
                    }) {
                        Image(systemName: "list.clipboard").foregroundColor(.purple)
                        Text("Retrieve Clipboard").foregroundColor(.purple)
                    }
                    Button(action: {
                        let separator = "\n" + "<hr style=\"border: none; height: 2px; background-color: #949494; margin: 20px 0;\">"
                        let notes = [renderedNotes1, renderedNotes2, renderedNotes3, renderedNotes4]
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
