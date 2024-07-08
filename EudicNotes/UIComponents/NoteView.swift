//
//  NotesView.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/7/7.
//

import SwiftUI
import WebKit
import Combine

class NoteDataHistoryManager: ObservableObject {
    static let historyManager = NoteDataHistoryManager()
    private let maxHistoryLimit = 10
    
    private var histories: [[String: String]]
    @Published var latestHistoryIndex: Int
    
    private init() {
        let storedHistories = UserDefaults.standard.array(forKey: "NoteDataHistory") as? [[String: String]] ?? []
        self.histories = storedHistories
        self.latestHistoryIndex = storedHistories.count - 1
    }
    
    func saveToHistory(entry: [String: String]) {
        histories.append(entry)
        if histories.count > maxHistoryLimit {
            histories.removeFirst()
        } else {
            latestHistoryIndex += 1
        }
        UserDefaults.standard.set(histories, forKey: "NoteDataHistory")
    }
    
    func deleteHistory(at index: Int) -> Bool {
        guard histories.indices.contains(index) else { return false }
        histories.remove(at: index)
        latestHistoryIndex -= 1
        UserDefaults.standard.set(histories, forKey: "NoteDataHistory")
        return true
    }
    
    func loadFromHistory(at index: Int) -> [String: String] {
        guard histories.indices.contains(index) else { return [:] }
        return histories[index]
    }
}

class NoteData: ObservableObject {
    // Properties to hold note data
    @Published var source: String = ""
    @Published var originalText: String = ""
    @Published var wordPhrase: String = ""
    @Published var notes: String = ""
    @Published var tags: String = ""
    
    // Function to encapsulate all properties into a dictionary
    func toDictionary() -> [String: String] {
        return [
            "source": source,
            "originalText": originalText,
            "wordPhrase": wordPhrase,
            "notes": notes,
            "tags": tags
        ]
    }
    
    // Function to update properties with another instance's properties
    func updateWith(noteData: NoteData) {
        source = noteData.source
        originalText = noteData.originalText
        wordPhrase = noteData.wordPhrase
        notes = noteData.notes
        tags = noteData.tags
        noteHTMLContent = noteTemplateHTML
    }
    
    // Function to update properties from a dictionary
    func updateWithDictionary(_ dictionary: [String: String]) {
        source = dictionary["source"] ?? ""
        originalText = dictionary["originalText"] ?? ""
        wordPhrase = dictionary["wordPhrase"] ?? ""
        notes = dictionary["notes"] ?? ""
        tags = dictionary["tags"] ?? ""
        noteHTMLContent = noteTemplateHTML
    }
    
    // History management
    var historyManager: NoteDataHistoryManager
    @Published var historyIndex: Int
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.historyManager = NoteDataHistoryManager.historyManager
        self.historyIndex = historyManager.latestHistoryIndex
        
        historyManager.$latestHistoryIndex
            .receive(on: DispatchQueue.main)
            .sink { [weak self] latestHistoryIndex in
                guard let self = self else { return }
                self.historyIndex = min(self.historyIndex, latestHistoryIndex)
            }
            .store(in: &cancellables)
    }
    
    func saveToHistory() {
        historyManager.saveToHistory(entry: self.toDictionary())
        historyIndex = historyManager.latestHistoryIndex
    }
    
    func deleteHistory() {
        guard historyManager.deleteHistory(at: historyIndex) else { return }
        historyIndex = min(historyIndex, historyManager.latestHistoryIndex)
        loadFromHistory()
    }
    
    func loadFromHistory() {
        let result = historyManager.loadFromHistory(at: historyIndex)
        self.updateWithDictionary(result)
    }
    
    func loadPreviousHistory() {
        if historyIndex <= 0 { return }
        historyIndex -= 1
        loadFromHistory()
    }
    
    func loadNextHistory() {
        if historyIndex >= historyManager.latestHistoryIndex { return }
        historyIndex += 1
        loadFromHistory()
    }
    
    // Resources for rendering the note
    static private let useLocalResources = true
    static private let cssContent = "<style>\n" + (loadResourceContent(fileName: "notes", withExtension: "css") ?? "") + "\n</style>"
    static private let jsContent = "<script>\n" + (loadResourceContent(fileName: "notes", withExtension: "js") ?? "") + "\n</script>"
    
    static private func loadResourceContent(fileName: String, withExtension: String) -> String? {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: withExtension) else { return nil }
        return try? String(contentsOf: url)
    }
    
    // Generate HTML based on a list of NoteData
    static func constructNoteTemplateHTML(noteDataArray: [NoteData]) -> String {
        // Convert each NoteData to a dictionary and collect them into an array
        let dictionaries = noteDataArray.map { $0.toDictionary() }
        
        // Serialize the array of dictionaries to JSON for embedding in the HTML
        let jsonData = try! JSONSerialization.data(withJSONObject: dictionaries)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        // Construct the HTML content, embedding CSS and JS resources and serialized data
        return """
        <!DOCTYPE html>
        <html>
        <head>
            \(NoteData.useLocalResources ? NoteData.cssContent : #"<link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/Hazuki-295/EudicNotes@main/EudicNotes/Resources/notes.css">"#)
            <script>
                const noteDataArray = \(jsonString);
            </script>
            \(NoteData.useLocalResources ? NoteData.jsContent : #"<script src="https://cdn.jsdelivr.net/gh/Hazuki-295/EudicNotes@main/EudicNotes/Resources/notes.js"></script>"#)
        </head>
        <body>
            <!-- Notes will be inserted here -->
            <div class="Hazuki-note"></div>
        </body>
        </html>
        """
    }
    
    // Published property to hold the dynamically generated HTML content
    @Published var noteHTMLContent: String = ""
    var webView: WKWebView = WKWebView()
    
    // Function to update the HTML content with the template
    func updataHTMLContentWithTemplate() -> String {
        noteHTMLContent = noteTemplateHTML
        return noteHTMLContent
    }
    
    // Computed property to get the template HTML using fields of current NoteData
    var noteTemplateHTML: String {
        NoteData.constructNoteTemplateHTML(noteDataArray: [self])
    }
    
    func clearFields() {
        self.updateWithDictionary([:])
    }
    
    func clearLabels() {
        wordPhrase = ""
        originalText = originalText
            .removePlusSign()
            .removeAngleBrackets()
            .removeSquareBrackets()
    }
}

struct SingleNoteView: View {
    // Properties that determine the appearance of the view
    private let label: String
    private let labelColor: Color
    private let systemImage: String
    
    // Shared NoteData object
    @EnvironmentObject var sharedNoteData: NoteData
    
    // NoteData object for this view
    @ObservedObject var noteData: NoteData
    private let mainNoteData: Bool
    private let enableHistory: Bool
    
    // Properties to manage the WebView and TextEditor
    @State private var showTextEditor = false
    
    init (noteData: NoteData, mainNoteData: Bool = false, enableHistory: Bool = false, label: String, labelColor: Color = .black, systemImage: String = "note.text") {
        self.noteData = noteData
        self.mainNoteData = mainNoteData
        self.enableHistory = enableHistory
        
        self.label = label
        self.labelColor = labelColor
        self.systemImage = systemImage
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Label(label, systemImage: systemImage).foregroundColor(labelColor)
                
                if enableHistory {
                    Spacer()
                    Button(action: { noteData.loadPreviousHistory() }) {
                        Image(systemName: "arrowshape.turn.up.left")
                        Text("Previous")
                    }
                    .disabled(noteData.historyIndex <= 0)
                    
                    Text("\(noteData.historyIndex + 1)/\(noteData.historyManager.latestHistoryIndex + 1)")
                        .frame(minWidth: 40)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                        )
                    
                    Button(action: { noteData.loadNextHistory() }) {
                        Image(systemName: "arrowshape.turn.up.right")
                        Text("Next")
                    }
                    .disabled(noteData.historyIndex >= noteData.historyManager.latestHistoryIndex)
                }
            }
            
            ZStack {
                if !showTextEditor {
                    NLPView(htmlContent: $noteData.noteHTMLContent, webView: noteData.webView, initialJsToExecute: """
                        document.body.style.margin = '3px 6px';
                        const container = document.querySelector('.Hazuki-note');
                        if (container) container.style.zoom = '0.85';
                        """)
                } else {
                    CustomTextEditor(text: $noteData.noteHTMLContent)
                }
            }
            
            HStack {
                Button(action: { /* if let text = ClipboardManager.pasteFromClipboard() { noteData.recognizeNote(plainNote: text) } */ }) {
                    Image(systemName: "doc.on.clipboard")
                    Text("Paste")
                }
                if !mainNoteData {
                    Button(action: { noteData.updateWith(noteData: sharedNoteData) }) {
                        Image(systemName: "doc.on.clipboard")
                        Text("Paste From Main")
                    }
                }
                if enableHistory {
                    Button(action: { noteData.loadFromHistory() }) {
                        Image(systemName: "arrowshape.turn.up.backward.2")
                        Text("Load")
                    }
                    Button(action: { noteData.saveToHistory() }) {
                        Image(systemName: "externaldrive.badge.plus")
                        Text("Save")
                    }
                    Button(action: { noteData.deleteHistory() }) {
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

#Preview {
    ContentView()
}
