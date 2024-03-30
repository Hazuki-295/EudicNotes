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
                VStack() {
                    HStack {
                        Image(systemName: "book")
                        Text("Original Text:")
                    }
                    Button(action: {if let text = ClipboardManager.pasteFromClipboard() {originalText = text}}) {
                        Image(systemName: "doc.on.clipboard")
                        Text("Paste")
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
            
            HStack {
                Button("Generate Message") {self.generateMessage()}
                Button("Recognize Message") {self.recognizeMessage()}
                
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
        let pattern = #"\+([^+]*)\+"#
        let template = "<span style=\"color: #35A3FF; font-weight: bold;\">$1</span>" // light blue
        return replacePattern(in: input, pattern: pattern, template: template)
    }
    
    func replaceSquareBrackets(in input: String) -> String {
        let pattern = #"\[([^]]*)\]"#
        let template = "<span style=\"color: #67A78A; font-weight: bold;\">$1</span>" // green
        return replacePattern(in: input, pattern: pattern, template: template)
    }
    
    func replaceSquareBracketsNotes(in input: String) -> String { // signpost, special style
        let pattern = #"\[([^]]*)\]"#
        let template = "<span style=\"background-color: #647FB8; color: white; font-weight: bold; font-size: 85%; text-transform: uppercase; border-radius: 5px; padding: 1px 5px;\">$1</span>"
        return replacePattern(in: input, pattern: pattern, template: template)
    }
    
    func replaceAngleBrackets(in input: String) -> String {
        let pattern = "<([^>]*)>"
        let template = "<span style=\"color: #F51225; font-weight: bold\">$1</span>" // red
        return replacePattern(in: input, pattern: pattern, template: template)
    }
    
    func replaceAngleBracketsNotes(in input: String) -> String {
        let pattern = "<([^>]*)>"
        let template = "<span style=\"color: #5B75AA; font-weight: bold;\">$1</span>" // dark blue
        return replacePattern(in: input, pattern: pattern, template: template)
    }
    
    func replacePOS(in input: String) -> String { // special style, dark red
        let pattern = #"\b(?:noun|verb|adjective|adverb)\b"#
        let template = "<span style=\"color: rgba(196, 21, 27, 0.8); font-family: Georgia, 'Times New Roman', serif; font-size: 85%; font-style: italic; font-weight: bold; margin: 0 2px;\">$0</span>"
        return replacePattern(in: input, pattern: pattern, template: template)
    }
    
    func replaceSlash(in input: String) -> String { // special style, hotpink
        let pattern = #"(?<![<A-Za-z.])/[A-Za-z.]+(?:\s+[A-Za-z.]+)*"#
        let template = "<span style=\"color: hotpink; font-weight: bold; font-size: 80%; text-transform: uppercase; margin: 0px 2px;\">$0</span>"
        return replacePattern(in: input, pattern: pattern, template: template)
    }
    
    func replaceAsterisk(in input: String) -> String { // special style, light blue with mark
        let pattern = #"\*([^*]*)\*"#
        let template = "<span style=\"color: #0072CF; font-size: 15px; font-weight: 600; word-spacing: 0.1rem; background: linear-gradient(to bottom, rgba(0, 114, 207, 0) 55%, rgba(0,114,207,0.15) 55%, rgba(0,114,207,0.15) 100%); margin: 0 2px; padding-right: 3.75px\">$1</span>"
        return replacePattern(in: input, pattern: pattern, template: template)
    }
    
    func replaceExclamation(in input: String) -> String { // special style, tag
        let pattern = #"\!([^!]*)\!"#
        let template = "<span style=\"color: white; font-size: 15px; font-weight: 600; font-variant: small-caps; background: #0072CF; border-radius: 4px 0 0 4px; display: inline-block; height: 16px; line-height: 15px; margin-right: 5px; padding: 0 2px 0 5px; position: relative; transform: translateY(-1px);\">$1<span style=\"width: 0; height: 0; position: absolute; top: 0; left: 100%; border-style: solid; border-width: 8px 0 8px 6px; border-color: transparent transparent transparent #0072CF;\"></span></span>"
        return replacePattern(in: input, pattern: pattern, template: template)
    }
    
    func replaceAtSign(in input: String) -> String { // light blue without mark
        let pattern = "@([^@]*)@"
        let template = "<span style=\"font-family: Bookerly, optima, arial, helvetica, sans-serif; color: #0072CF; font-size: 15px; word-spacing: 0.1rem;\">$1</span>"
        return replacePattern(in: input, pattern: pattern, template: template)
    }
    
    func replaceAndSign(in input: String) -> String { // light green, italic, english
        let pattern = "&([^&]*)&"
        let template = "<span style=\"font-family: Bookerly, optima, arial, helvetica, sans-serif; color: #007A6C; font-size: 15px; font-style: italic; word-spacing: 0.1rem;\">$1</span>"
        return replacePattern(in: input, pattern: pattern, template: template)
    }
    
    func replaceCaretSign(in input: String) -> String { // light green, chinese
        let pattern = #"\^([^^]*)\^"#
        let template = "<span style=\"font-family: 'Source Han Serif CN', optima, arial, helvetica, sans-serif; color: #007A6C; font-size: 13.5px; word-spacing: 0.1rem; padding: 0 2px; margin-left: 2px; background: rgba(0, 122, 108, 0.2); border-radius: 3px;\">$1</span>"
        return replacePattern(in: input, pattern: pattern, template: template)
    }
    
    func generateMessage() {
        // Combine the input into a message
        let labelTemplate = "<span style=\"font-family: 'Times New Roman', optima, arial, helvetica, sans-serif; color: #716197; font-weight: bold;\">[%@]</span>" // purple
        
        // Source
        var modifiedSource = source
        if wordPhrase != "" {
            modifiedSource = highlightWord(in: modifiedSource)
        }
        modifiedSource = replacePlusSign(in: modifiedSource)
        
        // Original Text
        var modifiedOriginalText = originalText
        modifiedOriginalText = replaceAngleBrackets(in: modifiedOriginalText)
        
        if wordPhrase != "" {
            modifiedOriginalText = highlightWord(in: modifiedOriginalText)
        }
        modifiedOriginalText = replacePlusSign(in: modifiedOriginalText)
        modifiedOriginalText = replaceSquareBrackets(in: modifiedOriginalText)
        
        // Notes
        var modifiedNotes = notes
        if notes != "" {
            modifiedNotes = replaceAngleBracketsNotes(in: modifiedNotes)
            
            modifiedNotes = replacePOS(in: modifiedNotes)
            modifiedNotes = replaceSlash(in: modifiedNotes)
            modifiedNotes = replaceAtSign(in: modifiedNotes)
            modifiedNotes = replaceAndSign(in: modifiedNotes)
            modifiedNotes = replacePlusSign(in: modifiedNotes)
            modifiedNotes = replaceAsterisk(in: modifiedNotes)
            modifiedNotes = replaceCaretSign(in: modifiedNotes)
            modifiedNotes = replaceExclamation(in: modifiedNotes)
            modifiedNotes = replaceSquareBracketsNotes(in: modifiedNotes)
            
            modifiedNotes = modifiedNotes.replacingOccurrences(of: "⇿⇿", with: "<span style=\"color: #DE002D;\">,</span>")
            modifiedNotes = modifiedNotes.replacingOccurrences(of: "⇿", with: "<span style=\"color: #DE002D;\">⇿</span>")
            
            modifiedNotes = "\n\n" + String(format: labelTemplate, "Notes") + " " + modifiedNotes
        }
        
        // Tags
        var modifiedTags = tags
        if tags != "" {
            modifiedTags = "\n\n" + "<span style=\"font-family: 'Times New Roman', optima, arial, helvetica, sans-serif;\">\(tags)</span>"
        }
        
        generatedMessage = """
        \(String(format: labelTemplate, "Source")) \(modifiedSource)
        
        \(String(format: labelTemplate, "Original Text"))
        
        \(modifiedOriginalText)\(modifiedNotes)\(modifiedTags)
        """
        generatedMessage = "<span style=\"font-family: optima, arial, helvetica, sans-serif; font-size: 16px;\">" + generatedMessage + "</span>"
        
        ClipboardManager.copyToClipboard(textToCopy: generatedMessage)
    }
    
    func recognizeMessage() {
        // Regular expression patterns for capturing the contents, adjusted for multiline capture
        let sourcePattern = #"\[Source\]\s*([\s\S]+?)\s*(?=\[Original Text\])"#
        let originalTextPattern = #"\[Original Text\]\s*([\s\S]+?)\s*(?=\[Notes\]|#)"#
        let notesPattern = #"\[Notes\]\s*([\s\S]+?)\s*#"#
        let tagsPattern = "#[A-Za-z]+"
        
        // Function to find and trim contents using a regular expression pattern
        func findAndTrim(from text: String, using pattern: String, n: Int = 1) -> String? {
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
            guard let match = regex?.firstMatch(in: text, options: [], range: nsRange) else {
                return nil
            }
            
            if let range = Range(match.range(at: n), in: text) {
                return String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return nil
        }
        
        // Extracting and trimming the contents
        source = findAndTrim(from: generatedMessage, using: sourcePattern) ?? ""
        originalText = findAndTrim(from: generatedMessage, using: originalTextPattern) ?? ""
        wordPhrase = ""
        notes = findAndTrim(from: generatedMessage, using: notesPattern) ?? ""
        tags = findAndTrim(from: generatedMessage, using: tagsPattern, n: 0) ?? ""
    }
    
    func clearFields() {
        source = ""
        originalText = ""
        wordPhrase = ""
        notes = ""
        //tags = ""
        generatedMessage = ""
    }
}

#Preview {
    MainView()
}
