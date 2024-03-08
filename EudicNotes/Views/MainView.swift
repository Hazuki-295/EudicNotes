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
                ComboBox(text: $source, options: sourceHistory.history, label: "Source")
                    .onSubmit {sourceHistory.addToHistory(newEntry: source)}
            }
            
            // Original Text
            HStack {
                Image(systemName: "book")
                Text("Original Text:")
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
                TextField("Enter Notes", text: $notes)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Tags
            HStack {
                Image(systemName: "tag")
                ComboBox(text: $tags, options: tagsHistory.history, label: "Tags")
                    .onSubmit {tagsHistory.addToHistory(newEntry: tags)}
            }
            
            HStack {
                Button("Generate Message") {
                    self.generateMessage()
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
            
            HStack {
                Image(systemName: "note.text")
                Text("Generated Notes:")
            }
            .padding(.top, 5)
            
            CustomTextEditor(text: $generatedMessage, minHeight: 200)
            
            HStack {
                Button(action: {
                    ClipboardManager.copyToClipboard(textToCopy: generatedMessage)
                }) {
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
    
    // Generalized function to replace patterns in a string
    func replacePattern(in input: String, pattern: String, template: String, options: NSRegularExpression.Options = []) -> String {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: options)
            let range = NSRange(input.startIndex..<input.endIndex, in: input)
            let modifiedString = regex.stringByReplacingMatches(in: input, options: [], range: range, withTemplate: template)
            return modifiedString
        } catch {
            print("Regex error: \(error)")
            return input
        }
    }
    
    func highlightWord(in input: String) -> String {
        let pattern = "\\b\(wordPhrase)\\b"
        let template = "+$0+"
        return replacePattern(in: input, pattern: pattern, template: template, options: .caseInsensitive)
    }
    
    func replacePlusSign(in input: String) -> String {
        let pattern = "\\+([^\\+]*)\\+"
        let template = "<span style=\"color: #35A3FF; font-weight:bold;\">$1</span>"
        return replacePattern(in: input, pattern: pattern, template: template)
    }
    
    func replacePlusSignNotes(in input: String) -> String {
        let pattern = "\\+([^\\+]*)\\+"
        let template = "<span style=\"color: #5B75AA; font-weight: bold;\">$1</span>"
        return replacePattern(in: input, pattern: pattern, template: template)
    }
    
    func replaceSquareBrackets(in input: String) -> String {
        let pattern = "\\[([^\\]]*)\\]"
        let template = "<span style=\"color: #67A78A; font-weight: bold;\">$1</span>"
        return replacePattern(in: input, pattern: pattern, template: template)
    }
    
    func replaceSquareBracketsNotes(in input: String) -> String {
        let pattern = "\\[([^\\]]*)\\]"
        let template = "<span style=\"background-color: #647FB8; color: white; font-weight: bold; font-size: 85%; text-transform: uppercase; border-radius: 5px; padding: 1px 5px;\">$1</span>"
        return replacePattern(in: input, pattern: pattern, template: template)
    }
    
    func replaceAngleBrackets(in input: String) -> String {
        let pattern = "<([^>]*)>"
        let template = "<span style=\"color: #F51225; font-weight: bold\">$1</span>"
        return replacePattern(in: input, pattern: pattern, template: template)
    }
    
    func replacePOS(in input: String) -> String {
        let pattern = "\\b(?:noun|verb|adjective|adverb)\\b"
        let template = "<span style=\"color: rgba(196, 21, 27, 0.8); font-family: Georgia, 'Times New Roman', serif; font-style: italic; font-weight: bold;\">$0</span>"
        return replacePattern(in: input, pattern: pattern, template: template)
    }
    
    func replaceSlash(in input: String) -> String {
        let pattern = "\\/[A-Za-z]+(?:\\s+[A-Za-z]+)*"
        let template = "<span style=\"color: hotpink; font-weight:bold; font-size:90%; text-transform: uppercase; padding: 0px 2px;\">$0</span>"
        return replacePattern(in: input, pattern: pattern, template: template)
    }
    
    func generateMessage() {
        let labelTemplate = "<span style=\"color: #716197; font-weight: bold;\">[%@]</span>"
        
        // Combine the input into a message
        var modifiedSource = source
        var modifiedOriginalText = originalText
        var modifiedNotes = notes
        var modifiedTags = tags
        
        modifiedOriginalText = replaceAngleBrackets(in: modifiedOriginalText)
        modifiedOriginalText = replaceSquareBrackets(in: modifiedOriginalText)
        
        if wordPhrase != "" {
            modifiedSource = highlightWord(in: modifiedSource)
            modifiedOriginalText = highlightWord(in: modifiedOriginalText)
        }
        modifiedSource = replacePlusSign(in: modifiedSource)
        modifiedOriginalText = replacePlusSign(in: modifiedOriginalText)
        
        if notes != "" {
            modifiedNotes = replaceSlash(in: modifiedNotes)
            modifiedNotes = replacePOS(in: modifiedNotes)
            modifiedNotes = replacePlusSignNotes(in: modifiedNotes)
            modifiedNotes = replaceSquareBracketsNotes(in: modifiedNotes)
            
            modifiedNotes = "\n\n" + String(format: labelTemplate, "Notes") + " " + modifiedNotes
        }
        
        if tags != "" {
            modifiedTags = "\n\n" + tags
        }
        
        generatedMessage = """
        \(String(format: labelTemplate, "Source")) \(modifiedSource)
        
        \(String(format: labelTemplate, "Original Text"))
        
        \(modifiedOriginalText)\(modifiedNotes)\(modifiedTags)
        """
        
        ClipboardManager.copyToClipboard(textToCopy: generatedMessage)
    }
    
    func recognizeMessage() {
        // Regular expression patterns for capturing the contents, adjusted for multiline capture
        let sourcePattern = "\\[Source\\]\\s*([\\s\\S]+?)\\s*(?=\\[Original Text\\])"
        let originalTextPattern = "\\[Original Text\\]\\s*([\\s\\S]+?)\\s*(?=\\[Notes\\]|#)"
        let notesPattern = "\\[Notes\\]\\s*([\\s\\S]+?)\\s*#"
        
        // Function to find and trim contents using a regular expression pattern
        func findAndTrimContents(from text: String, using pattern: String) -> String? {
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
            guard let match = regex?.firstMatch(in: text, options: [], range: nsRange) else {
                return nil
            }
            
            if let range = Range(match.range(at: 1), in: text) {
                return String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return nil
        }
        
        // Extracting and trimming the contents
        source = findAndTrimContents(from: generatedMessage, using: sourcePattern) ?? ""
        originalText = findAndTrimContents(from: generatedMessage, using: originalTextPattern) ?? ""
        notes = findAndTrimContents(from: generatedMessage, using: notesPattern) ?? ""
        wordPhrase = ""
    }
    
    func clearFields() {
        source = ""
        originalText = ""
        wordPhrase = ""
        notes = ""
        tags = ""
        generatedMessage = ""
    }
}

#Preview {
    MainView()
}
