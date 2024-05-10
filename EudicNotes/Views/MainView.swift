//
//  MainView.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/3/8.
//

import SwiftUI

class NoteData: ObservableObject {
    // Properties to hold note data
    @Published var source: String = ""
    @Published var originalText: String = ""
    @Published var wordPhrase: String = ""
    @Published var notes: String = ""
    @Published var tags: String = ""
    
    // Properties to hold user input and its rendered version
    @Published var userInputPlainNote: String = ""
    @Published var userInputRenderedNote: String = ""
    
    private var autoUpdateEnabled: Bool = true
    
    static private let maxHistoryLimit = 5
    static private var histories = UserDefaults.standard.array(forKey: "NoteDataHistory") as? [[String: String]] ?? []
    static var latestHistoryIndex = histories.count - 1
    
    static private var noteDataTemp: NoteData = NoteData()
    
    init() {
        setupPipeline()
    }
    
    func setupPipeline() {
        $userInputPlainNote
            .removeDuplicates()
            .filter { _ in self.autoUpdateEnabled }
            .map { userInputPlainNote -> String in
                guard !userInputPlainNote.isEmpty else { return "" }
                NoteData.noteDataTemp.recognizeNote(plainNote: userInputPlainNote)
                return NoteData.noteDataTemp.renderedNote
            }
            .assign(to: &$userInputRenderedNote)
    }
    
    func updateWith(noteData: NoteData) {
        self.source = noteData.source
        self.originalText = noteData.originalText
        self.wordPhrase = noteData.wordPhrase
        self.notes = noteData.notes
        self.tags = noteData.tags
        
        self.autoUpdateEnabled.toggle()
        self.userInputPlainNote = noteData.userInputPlainNote
        self.userInputRenderedNote = noteData.userInputRenderedNote
        self.autoUpdateEnabled.toggle()
    }
    
    func manualUpdate() {
        self.autoUpdateEnabled.toggle()
        self.userInputPlainNote = self.plainNote
        self.userInputRenderedNote = self.renderedNote
        self.autoUpdateEnabled.toggle()
    }
    
    func saveToHistory() {
        let currentState = [
            "source": source,
            "originalText": originalText,
            "wordPhrase": wordPhrase,
            "notes": notes,
            "tags": tags,
            "userInputPlainNote": userInputPlainNote,
            "userInputRenderedNote": userInputRenderedNote
        ]
        NoteData.histories.append(currentState)
        if NoteData.histories.count > NoteData.maxHistoryLimit {
            NoteData.histories.removeFirst()
        }
        NoteData.latestHistoryIndex = NoteData.histories.count - 1
        UserDefaults.standard.set(NoteData.histories, forKey: "NoteDataHistory")
    }
    
    static func deleteHistory(at index: Int) {
        guard NoteData.histories.indices.contains(index) else { return }
        NoteData.histories.remove(at: index)
        NoteData.latestHistoryIndex = NoteData.histories.count - 1
        UserDefaults.standard.set(NoteData.histories, forKey: "NoteDataHistory")
    }
    
    func loadFromHistory(index: Int) {
        guard NoteData.histories.indices.contains(index) else { return }
        let history = NoteData.histories[index]
        source = history["source"] ?? ""
        originalText = history["originalText"] ?? ""
        wordPhrase = history["wordPhrase"] ?? ""
        notes = history["notes"] ?? ""
        tags = history["tags"] ?? ""
        
        autoUpdateEnabled.toggle()
        userInputPlainNote = history["userInputPlainNote"] ?? ""
        userInputRenderedNote = history["userInputRenderedNote"] ?? ""
        autoUpdateEnabled.toggle()
    }
    
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
