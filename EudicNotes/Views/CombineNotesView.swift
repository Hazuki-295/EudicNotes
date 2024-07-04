//
//  CombineNotesView.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/3/8.
//

import SwiftUI
import WebKit

class NoteData: ObservableObject {
    // Properties to hold note data
    @Published var source: String = ""
    @Published var originalText: String = ""
    @Published var wordPhrase: String = ""
    @Published var notes: String = ""
    @Published var tags: String = ""
    
    // @Published property for internal data management that will trigger view updates when changed
    @Published var _renderedNote: String = ""
    
    // Resources for rendering the note
    static private let useLocalResources = false
    static private var cssContent = useLocalResources ? "<style>\n" + (loadResourceContent(fileName: "notes", withExtension: "css") ?? "") + "\n</style>" :
    #"<link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/Hazuki-295/EudicNotes@main/EudicNotes/Resources/notes.css">"#
    static private var jsContent = useLocalResources ? "<script>\n" + (loadResourceContent(fileName: "notes", withExtension: "js") ?? "") + "\n</script>" :
    #"<script src="https://cdn.jsdelivr.net/gh/Hazuki-295/EudicNotes@main/EudicNotes/Resources/notes.js"></script>"#
    
    // History management
    static private let maxHistoryLimit = 5
    static private var histories = UserDefaults.standard.array(forKey: "NoteDataHistory") as? [[String: String]] ?? []
    static var latestHistoryIndex = histories.count - 1
    
    func updateWith(noteData: NoteData) {
        self.source = noteData.source
        self.originalText = noteData.originalText
        self.wordPhrase = noteData.wordPhrase
        self.notes = noteData.notes
        self.tags = noteData.tags
        
        self._renderedNote = noteData._renderedNote
    }
    
    func saveToHistory() {
        let currentState = [
            "source": source,
            "originalText": originalText,
            "wordPhrase": wordPhrase,
            "notes": notes,
            "tags": tags,
            
            "renderedNote": _renderedNote
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
        
        _renderedNote = history["renderedNote"] ?? ""
    }
    
    // Public computed property to process and display the note in a specific HTML format
    var renderedNote: String {
        let htmlContent = """
        <!DOCTYPE html>
        <html>
        <head>
            \(NoteData.cssContent)
        </head>
        <body>
            <div class="notes-container">
                <div class="notes-label" label-data="Source"> \(formatSource())</div><br>
                <br>
                <div class="notes-label" label-data="Original Text"><br>
                    <br>
                    \(formatOriginalText())
                </div>
                \(formatNotes())\(formatTags())
            </div>
            \(NoteData.jsContent)
        </body>
        </html>
        """
        
        let escapedHTMLContent = htmlContent.replacingOccurrences(of: "\"", with: "&quot;")
        
        let iframe = #"<iframe class="notes-iframe" srcdoc="\#(escapedHTMLContent)" style="width: 100%; height: 0; border: none; padding: 0; margin: 0;"></iframe>"#
        
        return iframe
    }
    
    // Helper functions to format different parts of the note
    private func formatSource() -> String {
        return (wordPhrase.isEmpty ? source : source.highlightWord(wordPhrase))
            .replacePlusSign()
    }
    
    private func formatOriginalText() -> String {
        return (wordPhrase.isEmpty ? originalText : originalText.highlightWord(wordPhrase))
            .replaceAngleBrackets().replacePlusSign().replaceSquareBrackets()
            .replacingOccurrences(of: "\n", with: "<br>")
    }
    
    private func formatNotes() -> String {
        return notes.isEmpty ? "" : #"<br><br><div class="notes-label" label-data="Notes"> "# + notes
            .replaceAngleBrackets().replacePlusSign().replaceSquareBrackets()
            .replacePOS().replaceSlash().replaceAsterisk().replaceExclamation().replaceAtSign().replaceAndSign()
            .replacingOccurrences(of: "\n", with: "<br>") + #"</div>"#
    }
    
    private func formatTags() -> String {
        if (tags.isEmpty) { return "" }
        
        let tagList = tags.split(separator: " ")
        let formattedTags = tagList.map { tag in
            let trimmed = tag.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
            return #"<span class="notes-tag">\#(trimmed)</span>"#
        }
        
        return "<br><br>" + formattedTags.joined(separator: " ")
    }
    
    func recognizeNote(plainNote: String) {
        
    }
    
    func clearFields() {
        (source, originalText, wordPhrase, notes, tags, _renderedNote) = ("", "", "", "", "", "")
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
    
    @State private var webView: WKWebView? = nil
    
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
            
            ZStack {
                // visible by default
                if !showTextEditor {
                    NLPView(htmlContent: noteData._renderedNote, initialJsToExecute: """
                        document.body.style.margin = '3px 8px';
                        const container = document.querySelector('.notes-container');
                        if (container) container.style.zoom = '0.8';
                        """, webView: $webView)
                }
                
                // hidden by default
                if showTextEditor {
                    CustomTextEditor(text: $noteData._renderedNote)
                }
            }
            
            HStack {
                Button(action: { if let text = ClipboardManager.pasteFromClipboard() { noteData.recognizeNote(plainNote: text) } }) {
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
                    Button(action: { noteData.loadFromHistory(index: historyIndex) }) {
                        Image(systemName: "arrowshape.turn.up.backward.2")
                        Text("Load")
                    }
                    Button(action: { noteData.saveToHistory(); historyIndex = NoteData.latestHistoryIndex }) {
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
                        // (noteData1.userInputPlainNote, noteData2.userInputPlainNote, noteData3.userInputPlainNote, noteData4.userInputPlainNote) = (noteComponents[0], noteComponents[1], noteComponents[2], noteComponents[3])
                    }) {
                        Image(systemName: "list.clipboard").foregroundColor(.purple)
                        Text("Retrieve Clipboard").foregroundColor(.purple)
                    }
                    Button(action: {
                        let separator = "\n" + "<hr style=\"border: none; height: 2px; background-color: #949494; margin: 20px 0;\">"
                        // let notes = [noteData1.userInputRenderedNote, noteData2.userInputRenderedNote, noteData3.userInputRenderedNote, noteData4.userInputRenderedNote]
                        // combinedNotes = notes.filter { !$0.isEmpty }.joined(separator: separator)
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
