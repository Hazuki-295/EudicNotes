//
//  ContentView.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/3/6.
//

import SwiftUI

struct ContentView: View {
    @State private var source: String = ""
    @StateObject private var sourceHistory = InputHistoryViewModel()
    
    @State private var selectedTag: String = "#Genshin" // Default selected tag
    let tagOptions = ["#Genshin", "#IELTS"] // List of tag options
    
    @State private var originalText: String = ""
    @State private var wordPhrase: String = ""
    @State private var notes: String = ""
    @State private var tags: String = ""
    @State private var generatedMessage: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Source
            ComboBox(text: $source, options: sourceHistory.history)
                .onSubmit {
                    sourceHistory.addToHistory(newEntry: source)
                }
            
            // Original Text
            HStack {
                Text("Original Text:")
                TextEditor(text: $originalText)
                    .frame(minHeight: 100, maxHeight: .infinity)
                    .lineSpacing(2)
                    .padding(5)
                    .background(Color.white)
                    .cornerRadius(5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.gray, lineWidth: 1)
                    )
            }
            
            // Word or Phrase
            HStack {
                Text("Word / Phrase:")
                TextField("Enter Word or Phrase", text: $wordPhrase)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Notes
            HStack {
                Text("Notes:")
                TextField("Enter Notes", text: $notes)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Tags
            Picker("Tags:", selection: $selectedTag) {
                ForEach(tagOptions, id: \.self) { tag in
                    Text(tag).tag(tag)
                }
            }
            .pickerStyle(MenuPickerStyle())
            
            HStack {
                // Left-aligned buttons
                Button("Generate Message") {
                    self.generateMessage()
                }
                Button("Recognize Message") {
                    self.recognizeMessage()
                }
                
                Spacer()
                
                // Right-aligned buttons
                Button("Clear Fields") {
                    source = ""
                    originalText = ""
                    wordPhrase = ""
                    notes = ""
                    generatedMessage = ""
                }
                Button("Option") {
                    
                }
            }
            
            Text("Generated Message:").padding(.top, 15)
            
            TextEditor(text: $generatedMessage)
                .frame(minHeight: 200, maxHeight: .infinity)
                .lineSpacing(2)
                .padding(5)
                .background(Color.white)
                .cornerRadius(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.gray, lineWidth: 1)
                )
            
            HStack {
                Button("Copy to Clipboard") {
                    self.copyToClipboard(textToCopy: generatedMessage)
                }
                Button("Paste from Clipboard") {
                    self.pasteFromClipboard()
                }
            }
        }
        .padding()
        .padding(.top, 10)
        .padding(.bottom, 10)
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
            
            modifiedNotes = String(format: labelTemplate, "Notes") + " " + modifiedNotes + "\n\n"
        }
        
        generatedMessage = """
        \(String(format: labelTemplate, "Source")) \(modifiedSource)
        
        \(String(format: labelTemplate, "Original Text"))
        
        \(modifiedOriginalText)
        
        \(modifiedNotes)\(selectedTag)
        """
        
        self.copyToClipboard(textToCopy: generatedMessage)
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
    
    func copyToClipboard(textToCopy: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(textToCopy, forType: .string)
    }
    
    func pasteFromClipboard() {
        let pasteboard = NSPasteboard.general
        if let string = pasteboard.string(forType: .string) {
            generatedMessage = string
            self.recognizeMessage()
        }
    }
}

#Preview {
    ContentView()
}
