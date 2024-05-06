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
    
    @State private var plainNotes: String = ""
    @State private var renderedNotes: String = ""
    
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
            .frame(height: 150)
            
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
                CustomTextEditor(text: $notes)
            }
            .frame(height: 100)
            
            // Tags
            HStack {
                Image(systemName: "tag")
                ComboBox(text: $tags, options: tagsHistory.history.sorted(), label: "Tags")
                    .onSubmit {tagsHistory.addToHistory(newEntry: tags)}
            }
            
            // buttons
            HStack {
                Button("Generate Message") {
                    // generatedMessage = MessageUtils.generateMessage(source: self.source, originalText: self.originalText, wordPhrase: self.wordPhrase, notes: self.notes, tags: self.tags)
                    // ClipboardManager.copyToClipboard(textToCopy: generatedMessage)
                }
                Button("Recognize Message") {
                    // wordPhrase = ""
                    // MessageUtils.recognizeMessage(in: generatedMessage, source: &self.source, originalText: &self.originalText, notes: &self.notes, tags: &self.tags)
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
            .padding(.trailing, 5)
            
            SingleNotesView(label: "Combined Notes", labelColor: .purple, systemImage: "note.text", plainNotes: $plainNotes, renderedNotes: $renderedNotes)
                .frame(height: 200)
        }
        .padding()
    }
    
    func clearFields() {
        (source, originalText, wordPhrase, notes, tags, plainNotes) = ("", "", "", "", "", "")
    }
    
    func clearLabels() {
        originalText = originalText
            .replacePlusSign(revert: true)
            .replaceAngleBrackets(revert: true)
            .replaceSquareBrackets(revert: true)
    }
}

struct MessageUtils {
    // Centralized style templates
    private static let styleTemplates = [
        "label": "<span style=\"font-family: Bookerly; color: #4F7DC0; font-weight: 500;\">[%@]</span>", // deep sky blue
        "content": "<span style=\"font-family: Optima, Bookerly, 'Source Han Serif CN'; font-size: 16px;\">%@</span>",
        "Bookerly": "<span style=\"font-family: Bookerly;\">%@</span>"
    ]
    
    // Combine the input into a single message
    static func generateMessage(source: String, originalText: String, wordPhrase: String = "", notes: String, tags: String) -> String {
        let modifiedSource = formatSource(wordPhrase.isEmpty ? source : source.highlightWord(wordPhrase))
        let modifiedOriginalText = formatOriginalText(wordPhrase.isEmpty ? originalText : originalText.highlightWord(wordPhrase))
        let modifiedNotes = notes.isEmpty ? "" : formatNotes(notes)
        let modifiedTags = tags.isEmpty ? "" : formatTags(tags)
        
        // Combine into the final message
        let message = """
            \(String(format: styleTemplates["label"]!, "Source")) \(modifiedSource)
            
            \(String(format: styleTemplates["label"]!, "Original Text"))
            
            \(modifiedOriginalText)\(modifiedNotes)\(modifiedTags)
            """
        return String(format: styleTemplates["content"]!, message)
    }
    
    // Recognize the content from the message using regex
    static func recognizeMessage(in input: String, source: inout String, originalText: inout String, notes: inout String, tags: inout String) {
        let patterns = [
            "source": #"\[Source\]([\s\S]+?)(?=\[Original Text\])"#, // capturing with non-greedy plus
            "originalText": #"\[Original Text\]([\s\S]+?)(?=(\[Notes\]|#|$))"#, // stop at "[Notes]" or tags or end of string
            "notes": #"\[Notes\]([\s\S]+?)(?=(#|$))"#, // stop at tags or end of string
            "tags": "(#[A-Za-z]+)" // capture tags
        ]
        source = matchAndTrim(input, withRegexPattern: patterns["source"]!)
        originalText = matchAndTrim(input, withRegexPattern: patterns["originalText"]!)
        notes = matchAndTrim(input, withRegexPattern: patterns["notes"]!)
        tags = matchAndTrim(input, withRegexPattern: patterns["tags"]!)
    }
    
    // Helper function for regex matching and trimming the first and only capturing group using a regular expression pattern
    private static func matchAndTrim(_ input: String, withRegexPattern pattern: String) -> String {
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
    
    // Helper functions to format different parts of the message
    private static func formatSource(_ source: String) -> String {
        return source.replacePlusSign()
    }
    
    private static func formatOriginalText(_ text: String) -> String {
        return text.replaceAngleBrackets().replacePlusSign().replaceSquareBrackets()
    }
    
    private static func formatNotes(_ notes: String) -> String {
        return "\n\n" + String(format: styleTemplates["label"]!, "Notes") + " " + notes.replaceAngleBrackets()
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
    
    private static func formatTags(_ tags: String) -> String {
        return "\n\n" + String(format: styleTemplates["Bookerly"]!, tags)
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
