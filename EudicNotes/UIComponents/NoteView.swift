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
    private let maxHistoryLimit = 10
    private var useUserDefaults: Bool
    
    @Published var histories: [[String: String]]
    @Published var latestHistoryIndex: Int
    
    init(useUserDefaults: Bool = true, histories: [[String: String]] = []) {
        self.useUserDefaults = useUserDefaults
        
        var initialHistories = histories
        if useUserDefaults {
            initialHistories = UserDefaults.standard.array(forKey: "NoteDataHistory") as? [[String: String]] ?? []
        }
        
        self.histories = initialHistories
        self.latestHistoryIndex = initialHistories.count - 1
    }
    
    func saveToHistory(entry: [String: String]) {
        histories.append(entry)
        if histories.count > maxHistoryLimit {
            histories.removeFirst()
        } else {
            latestHistoryIndex += 1
        }
        
        if useUserDefaults {
            UserDefaults.standard.set(histories, forKey: "NoteDataHistory")
        }
    }
    
    func deleteHistory(at index: Int) -> Bool {
        guard histories.indices.contains(index) else { return false }
        histories.remove(at: index)
        latestHistoryIndex -= 1
        
        if useUserDefaults {
            UserDefaults.standard.set(histories, forKey: "NoteDataHistory")
        }
        return true
    }
    
    func loadFromHistory(at index: Int) -> [String: String]? {
        guard histories.indices.contains(index) else { return nil }
        return histories[index]
    }
    
    func switchHistorySource(useUserDefaults: Bool, newHistories: [[String: String]] = []) {
        self.useUserDefaults = useUserDefaults
        if useUserDefaults {
            self.histories = UserDefaults.standard.array(forKey: "NoteDataHistory") as? [[String: String]] ?? []
        } else {
            self.histories = newHistories
        }
        self.latestHistoryIndex = self.histories.count - 1
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
        updataHTMLContentWithTemplate()
    }
    
    // Function to update properties from a dictionary
    func updateWithDictionary(_ dictionary: [String: String]) {
        source = dictionary["source"] ?? ""
        originalText = dictionary["originalText"] ?? ""
        wordPhrase = dictionary["wordPhrase"] ?? ""
        notes = dictionary["notes"] ?? ""
        tags = dictionary["tags"] ?? ""
        updataHTMLContentWithTemplate()
    }
    
    // History management
    var historyManager: NoteDataHistoryManager
    @Published var historyIndex: Int
    
    init(useUserDefaults: Bool = true, histories: [[String: String]] = []) {
        self.historyManager = NoteDataHistoryManager(useUserDefaults: useUserDefaults, histories: histories)
        self.historyIndex = historyManager.latestHistoryIndex
        self.webView.loadHTMLString(noteTemplateHTML(), baseURL: nil)
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
        if let result = historyManager.loadFromHistory(at: historyIndex) {
            self.updateWithDictionary(result)
        }
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
    static private func loadResourceContent(fileName: String, withExtension: String) -> String? {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: withExtension) else { return nil }
        return try? String(contentsOf: url)
    }
    
    // Generate HTML based on a list of NoteData
    static func constructNoteTemplateHTML(dictionaries: [[String: String]]) -> String {
        let jsonString = jsonify(dictionaries: dictionaries)
        
        return "<!DOCTYPE html>" +
        "<html><head>" +
        "</head><body>" +
        "<div class=\"Hazuki-note\"></div>" +
        "<script type=\"application/json\" id=\"noteDataArray\">\(jsonString)</script>" +
        "<script>const noteDataArray = JSON.parse(document.getElementById('noteDataArray').textContent);</script>" +
        "<script>\(loadResourceContent(fileName: "notes.bundle", withExtension: "js") ?? "")</script>" +
        "</body></html>"
    }
    
    // Function to serialize the array of dictionaries to JSON
    static func jsonify(dictionaries: [[String: String]]) -> String {
        let jsonData = try! JSONSerialization.data(withJSONObject: dictionaries)
        return String(data: jsonData, encoding: .utf8)!
    }
    
    // Published property to hold the dynamically generated HTML content
    @Published var noteHTMLContent: String = ""
    var webView: WKWebView = WKWebView()
    
    // Function to update the HTML content with the template
    func updataHTMLContentWithTemplate() {
        noteHTMLContent = noteTemplateHTML()
    }
    
    // Construct template HTML using fields of current NoteData
    func noteTemplateHTML(useHistories: Bool = false) -> String {
        let dictionaries = useHistories ? self.historyManager.histories : [self.toDictionary()]
        return NoteData.constructNoteTemplateHTML(dictionaries: dictionaries)
    }
    
    // Construct JSON string using fields of current NoteData
    func noteJSON(useHistories: Bool = false) -> String {
        let dictionaries = useHistories ? self.historyManager.histories : [self.toDictionary()]
        return NoteData.jsonify(dictionaries: dictionaries)
    }
    
    func clearFields() {
        self.updateWithDictionary([:])
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
    private let combinedNoteData: Bool
    
    init (noteData: NoteData, mainNoteData: Bool = false, enableHistory: Bool = false, combinedNoteData: Bool = false,
          label: String, labelColor: Color = .black, systemImage: String = "note.text") {
        self.noteData = noteData
        self.mainNoteData = mainNoteData
        self.enableHistory = enableHistory
        self.combinedNoteData = combinedNoteData
        
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
            
            NLPView(htmlContent: $noteData.noteHTMLContent, webView: noteData.webView,
                    initialJsToExecute: #"document.head.appendChild(document.createElement("style")).innerHTML = ".Hazuki-note { margin: 1rem 0.5rem; zoom: 0.85; }";"#)
            
            HStack {
                Button(action: {
                    if let jsonString = ClipboardManager.pasteFromClipboard(),
                       let jsonData = jsonString.data(using: .utf8),
                       let noteDataArray = (try? JSONSerialization.jsonObject(with: jsonData)) as? [[String: String]] {
                        if !combinedNoteData {
                            noteData.updateWithDictionary(noteDataArray[0])
                        } else {
                            noteData.historyManager.histories = noteDataArray
                        }
                    }
                }) {
                    Image(systemName: "doc.on.clipboard")
                    Text("Paste")
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
                if combinedNoteData {
                    Button(action: { ClipboardManager.copyToClipboard(textToCopy: noteData.noteTemplateHTML(useHistories: true)) }) {
                        HStack {
                            Image(systemName: "list.clipboard")
                            Text("Copy Template HTML")
                        }
                    }
                    Button(action: { ClipboardManager.copyToClipboard(textToCopy: noteData.noteJSON(useHistories: true)) }) {
                        HStack {
                            Image(systemName: "list.clipboard")
                            Text("Copy JSON")
                        }
                    }
                }
                Spacer()
                if !mainNoteData && !combinedNoteData {
                    Button(action: { noteData.updateWith(noteData: sharedNoteData) }) {
                        Image(systemName: "doc.on.clipboard")
                        Text("Paste from Main")
                    }
                    Button(action: { sharedNoteData.updateWith(noteData: noteData) }) {
                        Image(systemName: "list.clipboard")
                        Text("Copy to Main")
                    }
                }
                if mainNoteData {
                    Button(action: { WKWebView.clearWebCache() }) {
                        Image(systemName: "eraser.line.dashed")
                        Text("Clear Web Cache")
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
