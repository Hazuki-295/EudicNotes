//
//  MainView.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/3/8.
//

import SwiftUI

struct MainView: View {
    @State private var source: String = ""
    @State private var originalText: String = ""
    @State private var wordPhrase: String = ""
    @State private var notes: String = ""
    @State private var tags: String = ""
    @State private var generatedMessage: String = ""
    
    @StateObject private var sourceHistory = InputHistoryViewModel(variableName: "source")
    @StateObject private var tagsHistory = InputHistoryViewModel(variableName: "tags")
    
    private let optionsWindowController = OptionsWindowController()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Source
            HStack {
                Image(systemName: "text.book.closed")
                ComboBox(text: $source, options: sourceHistory.history.sorted(), label: "Source")
                    .onSubmit {sourceHistory.addToHistory(newEntry: source)}
            }
            
            // Original Text
            HStack {
                VStack {
                    HStack {
                        Image(systemName: "book")
                        Text("Original Text:")
                    }
                    Button(action: {self.clearLabels()}){
                        HStack {
                            Image(systemName: "eraser.line.dashed")
                            Text("Clear")
                        }
                    }
                }
                CustomTextEditor(text: $originalText)
            }
            
            // Word or Phrase
            HStack {
                Image(systemName: "highlighter")
                Text("Word / Phrase:")
                TextField("Enter Word or Phrase", text: $wordPhrase)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Notes
            HStack {
                Image(systemName: "bookmark")
                Text("Notes:")
                CustomTextEditor(text: $notes, minHeight: 40)
            }
            
            // Tags
            HStack {
                Image(systemName: "tag")
                ComboBox(text: $tags, options: tagsHistory.history.sorted(), label: "Tags")
                    .onSubmit {tagsHistory.addToHistory(newEntry: tags)}
            }
            
            // buttons
            HStack {
                Button("Generate Message") {
                    generatedMessage = MessageUtils.generateMessage(source: self.source, originalText: self.originalText, wordPhrase: self.wordPhrase, notes: self.notes, tags: self.tags)
                    ClipboardManager.copyToClipboard(textToCopy: generatedMessage)
                }
                Button("Recognize Message") {
                    self.recognizeMessage()
                }
                
                Spacer()
                
                Button(action: {self.clearFields()}){
                    HStack {
                        Image(systemName: "eraser.line.dashed")
                        Text("Clear")
                    }
                }
                Button(action: {optionsWindowController.openOptionsWindow()}) {
                    HStack {
                        Image(systemName: "gearshape")
                        Text("Options")
                    }
                }
            }
            
            // Generated Notes
            HStack {
                Image(systemName: "note.text")
                Text("Generated Notes:")
            }
            .padding(.top, 5)
            
            CustomTextEditor(text: $generatedMessage, minHeight: 200)
            
            HStack {
                Button(action: {ClipboardManager.copyToClipboard(textToCopy: generatedMessage)}) {
                    Image(systemName: "doc.on.doc")
                    Text("Copy to Clipboard")
                }
                Button(action: {
                    if let text = ClipboardManager.pasteFromClipboard() {
                        generatedMessage = text
                        self.recognizeMessage()
                    }
                }) {
                    Image(systemName: "doc.on.clipboard")
                    Text("Paste from Clipboard")
                }
            }
        }
        .padding()
    }
    
    func recognizeMessage() {
        MessageUtils.recognizeMessage(in: generatedMessage, source: &self.source, originalText: &self.originalText, notes: &self.notes, tags: &self.tags)
        wordPhrase = ""
    }
    
    func clearFields() {
        source = ""
        originalText = ""
        wordPhrase = ""
        notes = ""
        //tags = ""
        generatedMessage = ""
    }
    
    func clearLabels() {
        originalText = originalText
            .replacePlusSign(revert: true)
            .replaceAngleBrackets(revert: true)
            .replaceSquareBrackets(revert: true)
    }
}

struct MessageUtils {
    // Combine the input into a single message
    static func generateMessage(source: String, originalText: String, wordPhrase: String = "", notes: String, tags: String) -> String {
        let styleTemplates = [
            "label": "<span style=\"font-family: Bookerly; color: #4F7DC0; font-weight: 500;\">[%@]</span>", // deep sky blue
            "content": "<span style=\"font-family: Optima, Bookerly, 'Source Han Serif CN'; font-size: 16px;\">%@</span>",
            "Bookerly": "<span style=\"font-family: Bookerly;\">%@</span>"
        ]
        
        var (modifiedSource, modifiedOriginalText, modifiedNotes, modifiedTags) = (source, originalText, notes, tags)
        
        // Highlight the wordPhrase if provided
        if !wordPhrase.isEmpty {
            modifiedSource.highlightWord(wordPhrase: wordPhrase)
            modifiedOriginalText.highlightWord(wordPhrase: wordPhrase)
        }
        
        // Source
        modifiedSource = modifiedSource.replacePlusSign() // light blue
        
        // Original Text
        modifiedOriginalText = modifiedOriginalText.replaceAngleBrackets() // red
            .replacePlusSign() // light blue
            .replaceSquareBrackets() // green
        
        // Notes
        if !notes.isEmpty {
            modifiedNotes = modifiedNotes.replaceAngleBrackets() // red
                .replacePOS()
                .replaceSlash()
                .replaceAtSign()
                .replaceAndSign()
                .replacePlusSign() // light blue
                .replaceAsterisk()
                .replaceCaretSign()
                .replaceExclamation()
                .replaceSquareBrackets() // green
            
            modifiedNotes = "\n\n" + String(format: styleTemplates["label"]!, "Notes") + " " + modifiedNotes
        }
        
        if !tags.isEmpty {
            modifiedTags = "\n\n" + String(format: styleTemplates["Bookerly"]!, tags)
        }
        
        // Generate the final message
        let message = """
            \(String(format: styleTemplates["label"]!, "Source")) \(modifiedSource)
            
            \(String(format: styleTemplates["label"]!, "Original Text"))
            
            \(modifiedOriginalText)\(modifiedNotes)\(modifiedTags)
            """
        return String(format: styleTemplates["content"]!, message)
    }
    
    static func recognizeMessage(in input: String, source: inout String, originalText: inout String, notes: inout String, tags: inout String) {
        // Regular expression patterns for capturing the contents
        let sourcePattern = #"\[Source\]\s*([\s\S]+?)\s*(?=\[Original Text\])"#
        let originalTextPattern = #"\[Original Text\]\s*([\s\S]+?)\s*(?=\[Notes\]|#|$)"#
        let notesPattern = #"\[Notes\]\s*([\s\S]+?)\s*(?=#|$)"#
        let tagsPattern = "(#[A-Za-z]+)"
        
        // Function to find and trim the first and only capturing group using a regular expression pattern
        func matchAndTrim(_ input: String, withRegexPattern pattern: String) -> String {
            // Since we assume the regex is always correct, directly create the regex
            let regex = try! NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(input.startIndex..., in: input)
            
            // Access the first match
            guard let match = regex.firstMatch(in: input, options: [], range: range),
                  let captureRange = Range(match.range(at: 1), in: input) else {
                return ""  // Return an empty string if no content is captured
            }
            
            // Return the trimmed captured group, handle potentially empty capture gracefully
            return String(input[captureRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Extracting and trimming the contents
        source = matchAndTrim(input, withRegexPattern: sourcePattern)
        originalText = matchAndTrim(input, withRegexPattern: originalTextPattern)
        notes = matchAndTrim(input, withRegexPattern: notesPattern)
        tags = matchAndTrim(input, withRegexPattern: tagsPattern)
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
