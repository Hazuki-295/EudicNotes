//
//  MainView.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/3/8.
//

import SwiftUI

class NoteData: ObservableObject {
    @Published var source: String = ""
    @Published var originalText: String = ""
    @Published var wordPhrase: String = ""
    @Published var notes: String = ""
    @Published var tags: String = ""
    
    @Published var userInputPlainNote: String = ""
    @Published var userInputRenderedNote: String = ""
    
    private static let styleTemplates = [
        "content": "<span style=\"font-family: Optima, Bookerly, 'Source Han Serif CN'; font-size: 16px;\">%@</span>",
        "label": "<span style=\"font-family: Bookerly; color: #4F7DC0; font-weight: 500;\">[%@]</span>", // deep sky blue
        "tags": "<span style=\"font-family: Bookerly; color: #0D85FF;\">%@</span>"
    ]
    
    private static let patterns = [
        "source": #"\[Source\]([\s\S]+?)(?=\[Original Text\])"#, // capturing with non-greedy plus
        "originalText": #"\[Original Text\]([\s\S]+?)(?=(\[Notes\]|#|$))"#, // stop at "[Notes]" or tags or end of string
        "notes": #"\[Notes\]([\s\S]+?)(?=(#|$))"#, // stop at tags or end of string
        "tags": "(#[A-Za-z]+)" // capture tags
    ]
    
    var plainNote: String {
        """
        [Source] \(wordPhrase.isEmpty ? source : source.highlightWord(wordPhrase))
        
        [Original Text]
        
        \(wordPhrase.isEmpty ? originalText : originalText.highlightWord(wordPhrase))\(notes.isEmpty ? "" : "\n\n[Notes] \(notes)")\(tags.isEmpty ? "" : "\n\n\(tags)")
        """
    }
    
    var renderedNote: String {
        String(format: NoteData.styleTemplates["content"]!, """
        \(String(format: NoteData.styleTemplates["label"]!, "Source")) \(formatSource())
        
        \(String(format: NoteData.styleTemplates["label"]!, "Original Text"))
        
        \(formatOriginalText())\(formatNotes())\(formatTags())
        """)
    }
    
    // Helper functions to format different parts of the note
    private func formatSource() -> String {
        return (wordPhrase.isEmpty ? source : source.highlightWord(wordPhrase)).replacePlusSign()
    }
    
    private func formatOriginalText() -> String {
        return (wordPhrase.isEmpty ? originalText : originalText.highlightWord(wordPhrase)).replaceAngleBrackets().replacePlusSign().replaceSquareBrackets()
    }
    
    private func formatNotes() -> String {
        return notes.isEmpty ? "" : "\n\n" + String(format: NoteData.styleTemplates["label"]!, "Notes") + " " + notes.replaceAngleBrackets()
            .replacePOS()
            .replaceSlash()
            .replaceAtSign()
            .replaceAndSign()
            .replacePlusSign()
            .replaceAsterisk()
            .replaceCaretSign()
            .replaceExclamation()
            .replaceSquareBrackets()
    }
    
    private func formatTags() -> String {
        return tags.isEmpty ? "" : "\n\n" + String(format: NoteData.styleTemplates["tags"]!, tags)
    }
    
    init() {}
    
    init(plainNote: String) {
        recognizeNote(plainNote: plainNote)
    }
    
    func recognizeNote(plainNote: String) {
        source = NoteData.matchAndTrim(plainNote, NoteData.patterns["source"]!)
        originalText = NoteData.matchAndTrim(plainNote, NoteData.patterns["originalText"]!)
        wordPhrase = ""
        notes = NoteData.matchAndTrim(plainNote, NoteData.patterns["notes"]!)
        tags = NoteData.matchAndTrim(plainNote, NoteData.patterns["tags"]!)
    }
    
    // Helper function for regex matching and trimming the first and only capturing group using a regular expression pattern
    private static func matchAndTrim(_ input: String, _ pattern: String) -> String {
        // Since we assume the regex is always correct, directly create the regex
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(input.startIndex..., in: input)
        
        // Access the first match
        guard let match = regex.firstMatch(in: input, range: range),
              let captureRange = Range(match.range(at: 1), in: input) else {
            return "" // Return an empty string if no content is captured
        }
        
        // Return the trimmed captured group, handle potentially empty capture gracefully
        return String(input[captureRange]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func clearFields() {
        (source, originalText, wordPhrase, notes, tags) = ("", "", "", "", "")
        (userInputPlainNote, userInputRenderedNote) = ("", "")
    }
    
    func clearLabels() {
        wordPhrase = ""
        originalText = originalText
            .replacePlusSign(revert: true)
            .replaceAngleBrackets(revert: true)
            .replaceSquareBrackets(revert: true)
    }
}

struct MainView: View {
    @StateObject private var noteData = NoteData()
    @StateObject private var sourceHistory = InputHistoryViewModel(variableName: "source")
    @StateObject private var tagsHistory = InputHistoryViewModel(variableName: "tags")
    
    private let optionsWindowController = OptionsWindowController()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Source
            HStack {
                Image(systemName: "text.book.closed")
                ComboBox(text: $noteData.source, options: sourceHistory.history.sorted(), label: "Source")
                    .onSubmit {sourceHistory.addToHistory(newEntry: noteData.source)}
            }
            
            // Original Text
            HStack {
                VStack {
                    HStack {
                        Image(systemName: "book")
                        Text("Original Text:")
                    }
                    Button(action: { noteData.clearLabels(); }){
                        HStack {
                            Image(systemName: "eraser.line.dashed")
                            Text("Clear")
                        }
                    }
                }
                CustomTextEditor(text: $noteData.originalText)
            }
            .frame(height: 120)
            
            // Word or Phrase
            HStack {
                Image(systemName: "highlighter")
                Text("Word / Phrase:")
                TextField("Enter Word or Phrase", text: $noteData.wordPhrase)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Notes
            HStack {
                Image(systemName: "bookmark")
                Text("Notes:")
                CustomTextEditor(text: $noteData.notes)
            }
            .frame(height: 60)
            
            // Tags
            HStack {
                Image(systemName: "tag")
                ComboBox(text: $noteData.tags, options: tagsHistory.history.sorted(), label: "Tags")
                    .onSubmit {tagsHistory.addToHistory(newEntry: noteData.tags)}
            }
            
            // buttons
            HStack {
                Button(action: {
                    noteData.userInputPlainNote = noteData.plainNote
                    ClipboardManager.copyToClipboard(textToCopy: noteData.renderedNote)
                }) {
                    HStack {
                        Image(systemName: "paintbrush")
                        Text("Generate Notes")
                    }
                }
                Button(action: { ClipboardManager.copyToClipboard(textToCopy: noteData.userInputRenderedNote) }) {
                    HStack {
                        Image(systemName: "list.clipboard")
                        Text("Copy Row HTML")
                    }
                }
                
                Spacer()
                
                Button(action: { noteData.clearFields() }){
                    HStack {
                        Image(systemName: "eraser.line.dashed")
                        Text("Clear")
                    }
                }
                Button(action: { optionsWindowController.openOptionsWindow() }) {
                    HStack {
                        Image(systemName: "gearshape")
                        Text("Options")
                    }
                }
            }
            .padding(.trailing, 5)
            
            SingleNotesView(label: "Combined Notes", labelColor: .purple, systemImage: "note.text", noteData: noteData)
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
    MainView()
}
