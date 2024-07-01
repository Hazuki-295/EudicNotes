//
//  CombineNotesView.swift
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

struct SingleNotesView: View {
    private let label: String
    private let labelColor: Color
    private let systemImage: String
    
    @EnvironmentObject var sharedNoteData: NoteData
    @StateObject var noteData: NoteData
    private let mainNoteData: Bool
    
    @State private var showTextEditor = false
    
    @State private var historyIndex = NoteData.latestHistoryIndex
    
    init (label: String, labelColor: Color, systemImage: String, noteData: NoteData, mainNoteData: Bool = false) {
        self.label = label
        self.labelColor = labelColor
        self.systemImage = systemImage
        self._noteData = StateObject(wrappedValue: noteData)
        self.mainNoteData = mainNoteData
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Label(label, systemImage: systemImage).foregroundColor(labelColor)
                
                if mainNoteData {
                    Spacer()
                    Button(action: {
                        historyIndex -= 1
                        noteData.loadFromHistory(index: historyIndex)
                    }) {
                        Image(systemName: "arrowshape.turn.up.left")
                        Text("Previous")
                    }
                    .disabled(historyIndex <= 0)
                    
                    Text("\(historyIndex + 1)/\(NoteData.latestHistoryIndex + 1)")
                        .frame(minWidth: 40)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                        )
                    
                    Button(action: {
                        historyIndex += 1
                        noteData.loadFromHistory(index: historyIndex)
                    }) {
                        Image(systemName: "arrowshape.turn.up.right")
                        Text("Next")
                    }
                    .disabled(historyIndex == NoteData.latestHistoryIndex)
                }
            }
            
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
                if mainNoteData {
                    Button(action: {
                        noteData.loadFromHistory(index: historyIndex)
                    }) {
                        Image(systemName: "arrowshape.turn.up.backward.2")
                        Text("Load")
                    }
                    Button(action: {
                        noteData.saveToHistory()
                        historyIndex = NoteData.latestHistoryIndex
                    }) {
                        Image(systemName: "externaldrive.badge.plus")
                        Text("Save")
                    }
                    Button(action: {
                        NoteData.deleteHistory(at: historyIndex)
                        if historyIndex > NoteData.latestHistoryIndex {
                            historyIndex = NoteData.latestHistoryIndex
                        }
                        noteData.loadFromHistory(index: historyIndex)
                    }) {
                        Image(systemName: "trash")
                        Text("Delete")
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
