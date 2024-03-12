//
//  CombineNotesView.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/3/8.
//

import SwiftUI

struct SingleNotesView: View {
    @Binding var noteText: String
    var label: String
    var systemImage: String
    var labelColor: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            Label(label, systemImage: systemImage).foregroundColor(labelColor)
            CustomTextEditor(text: $noteText)
            HStack {
                Button(action: {
                    if let text = ClipboardManager.pasteFromClipboard() {
                        noteText = text
                    }
                }) {
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

class SavedNotes: ObservableObject {
    @Published var history: [String: String] = [:]
    
    init() {
        loadHistory()
    }
    
    func loadHistory() {
        history = UserDefaults.standard.dictionary(forKey: "savedNotes") as? [String: String] ?? [:]
    }
    
    func saveHistory() {
        UserDefaults.standard.set(history, forKey: "savedNotes")
    }
    
    func addToHistory(key: String, value: String) {
        guard !key.isEmpty, !value.isEmpty else { return }
        history[key] = value
        saveHistory()
    }
}

struct CombineNotesView: View {
    @State private var note1: String = ""
    @State private var note2: String = ""
    @State private var note3: String = ""
    @State private var note4: String = ""
    @State private var combinedNotes: String = ""
    
    private let separator:String = "\n<hr style=\"border: none; height: 2px; background-color: #949494; margin: 20px 0; margin-left: 0; margin-right: 0;\">"
    
    @State private var selectedkey: String = ""
    @StateObject private var savedNotes = SavedNotes()
    
    var sortedKeys: [String] {
        savedNotes.history.keys.sorted()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 15) {
                    SingleNotesView(noteText: $note1, label: "First Notes", systemImage: "note.text", labelColor: .brown)
                    SingleNotesView(noteText: $note2, label: "Second Notes", systemImage: "2.square", labelColor: .purple)
                    SingleNotesView(noteText: $note3, label: "Third Notes", systemImage: "3.square", labelColor: .blue)
                    SingleNotesView(noteText: $note4, label: "Fourth Notes", systemImage: "4.square", labelColor: .red)
                }
                .padding(.top, 5)
                
                Button(action: {
                    note1 = ""
                    note2 = ""
                    note3 = ""
                    note4 = ""
                    selectedkey = ""
                }) {
                    Image(systemName: "eraser.line.dashed")
                    Text("Clear All")
                }
                
                HStack {
                    Button(action: {
                        let notes = [note1, note2, note3, note4]
                        combinedNotes = notes.filter { !$0.isEmpty }.joined(separator: separator)
                        ClipboardManager.copyToClipboard(textToCopy: combinedNotes)
                    }) {
                        Image(systemName: "book").foregroundColor(.indigo)
                        Text("Combine Notes").foregroundColor(.indigo)
                    }
                    Button(action: {
                        savedNotes.addToHistory(key: selectedkey, value: combinedNotes)
                    }) {
                        Image(systemName: "square.and.arrow.down").foregroundColor(.indigo)
                        Text("Save").foregroundColor(.indigo)
                    }
                }
                .position(x: geometry.size.width / 2 - 20, y: geometry.safeAreaInsets.top + 10)
                
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                    ComboBox(text: $selectedkey, options: sortedKeys, label: "Notes Name")
                        .onChange(of: selectedkey) {
                            combinedNotes = savedNotes.history[selectedkey] ?? ""
                            
                            let noteComponents = combinedNotes.split(separator: separator).map(String.init)
                            note1 = noteComponents.indices.contains(0) ? noteComponents[0] : ""
                            note2 = noteComponents.indices.contains(1) ? noteComponents[1] : ""
                            note3 = noteComponents.indices.contains(2) ? noteComponents[2] : ""
                            note4 = noteComponents.indices.contains(3) ? noteComponents[3] : ""
                            
                        }
                }
                .frame(minWidth: 300, maxWidth: 300)
                .position(x: geometry.size.width / 2 - 20, y: geometry.safeAreaInsets.top + 165)
            }
            .padding(.top, 5)
            .padding(.bottom)
            .padding(.leading)
            .padding(.trailing)
        }
    }
}

#Preview {
    OptionsView()
}
