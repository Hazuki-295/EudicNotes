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
    
    // Generalized function to replace patterns in a string
    func replacePattern(in input: String, withRegexPattern regexPattern: String,
                        usingTemplate replacementTemplate: String, options regexOptions: NSRegularExpression.Options = [],
                        transform: ((String) -> String)? = nil) -> String {
        do {
            // Compile the regular expression based on the provided pattern and options
            let regex = try NSRegularExpression(pattern: regexPattern, options: regexOptions)
            let range = NSRange(input.startIndex..<input.endIndex, in: input)
            let nsInput = input as NSString
            let resultString = NSMutableString(string: nsInput)
            
            // Find all matches and process them in reverse order to preserve indices for replacements
            let matches = regex.matches(in: input, options: [], range: range).reversed()
            for match in matches {
                // Process each capturing group within the match
                var currentReplacement = replacementTemplate
                for groupIndex in 0..<match.numberOfRanges {
                    let groupRange = match.range(at: groupIndex)
                    if groupRange.location != NSNotFound, groupRange.length != 0 {
                        let matchedSubstring = nsInput.substring(with: groupRange)
                        // Apply any provided transformation to the matched substring
                        let transformedSubstring = transform?(matchedSubstring) ?? matchedSubstring
                        // Replace the placeholder corresponding to the current group index
                        currentReplacement = currentReplacement.replacingOccurrences(of: "$\(groupIndex)", with: transformedSubstring, options: .literal, range: nil)
                    }
                }
                // Apply the final replacement to the result string
                resultString.replaceCharacters(in: match.range, with: currentReplacement)
            }
            
            return resultString as String
        } catch {
            print("Regex error: \(error.localizedDescription)")
            return input
        }
    }
    
    private let invisibleTemplate = "<span style=\"opacity: 0; position: absolute;\">%@</span>"
    
    // 1. Colorful fonts
    func highlightWord(_ input: String) -> String {
        let pattern = "\\b\(wordPhrase)\\b"
        let template = "+$0+"
        return replacePattern(in: input, withRegexPattern: pattern, usingTemplate: template, options: .caseInsensitive)
    }
    
    func replacePlusSign(_ input: String) -> String {
        let pattern = #"\+([^+]*)\+"#
        let baseTemplate = "<span style=\"color: #35A3FF; font-weight: bold;\">$1</span>" // light blue
        let template = String(format: invisibleTemplate, "+") + baseTemplate + String(format: invisibleTemplate, "+")
        return replacePattern(in: input, withRegexPattern: pattern, usingTemplate: template)
    }
    
    func replaceSquareBrackets(_ input: String) -> String {
        let pattern = #"\[([^]]*)\]"#
        let baseTemplate = "<span style=\"color: #67A78A; font-weight: bold;\">$1</span>" // green
        let template = String(format: invisibleTemplate, "[") + baseTemplate + String(format: invisibleTemplate, "]")
        return replacePattern(in: input, withRegexPattern: pattern, usingTemplate: template)
    }
    
    func replaceAngleBrackets(_ input: String) -> String {
        let pattern = "<([^>]*)>"
        let baseTemplate = "<span style=\"color: #F51225; font-weight: bold\">$1</span>" // red
        let template = String(format: invisibleTemplate, "<") + baseTemplate + String(format: invisibleTemplate, ">")
        return replacePattern(in: input, withRegexPattern: pattern, usingTemplate: template)
    }
    
    // 2. LDOCE Style
    func replacePOS(_ input: String) -> String { // special style, dark red
        let patternTemplatePairs: [String: String] = [
            #"\b(noun|verb|adjective|adverb|preposition|conjunction)\b"#: "<span style=\"font-family: Georgia; color: rgba(196, 21, 27, 0.8); font-size: 85%; font-weight: bold; font-style: italic; margin: 0 2px;\">$1</span>",
            #"\b(Phrasal Verb)\b"#: "<span style=\"font-family: Optima; color: rgba(196, 21, 27, 0.8); font-size: 74%; border: 1px solid rgba(196, 21, 27, 0.8); padding: 0px 3px; margin: 0 2px;\">$1</span>",
            #"\b(Idioms)\b"#: "<span style=\"font-family: Optima; color: #0072CF; font-size: 15px; font-weight: 600; word-spacing: 0.1rem; margin: 0 2px;\">$1</span>"
        ]
        
        var modifiedInput = input
        for (pattern, template) in patternTemplatePairs {
            modifiedInput = replacePattern(in: modifiedInput, withRegexPattern: pattern, usingTemplate: template)
        }
        return modifiedInput
    }
    
    func replaceSlash(_ input: String) -> String { // special style, hotpink
        let pattern = #"(?<![<A-Za-z.])/[A-Za-z.]+(?:\s+[A-Za-z.]+)*"#
        let template = "<span style=\"font-family: Optima; color: hotpink; font-size: 80%; font-weight: bold; text-transform: uppercase; margin: 0px 2px;\">$0</span>"
        return replacePattern(in: input, withRegexPattern: pattern, usingTemplate: template)
    }
    
    // 3. OALD Style
    func replaceAsterisk(_ input: String) -> String { // special style, light blue with mark
        let pattern = #"\*([^*]*)\*"#
        let baseTemplate = "<span style=\"font-family: Optima; color: #0072CF; font-size: 15px; font-weight: 600; word-spacing: 0.1rem; background: linear-gradient(to bottom, rgba(0, 114, 207, 0) 55%, rgba(0, 114, 207, 0.15) 55%, rgba(0, 114, 207, 0.15) 100%); margin: 0 2px; padding-right: 3.75px\">$1</span>"
        let template = String(format: invisibleTemplate, "*") + baseTemplate + String(format: invisibleTemplate, "*")
        return replacePattern(in: input, withRegexPattern: pattern, usingTemplate: template, transform: { match in
            var modifiedMatch = match
                .replacingOccurrences(of: ",", with: "<span style=\"color: #DE002D;\">,</span>")
                .replacingOccurrences(of: "⇿", with: "<span style=\"color: #DE002D;\">⇿</span>")
            
            if let index = modifiedMatch.firstIndex(where: { $0.isCJK }) {
                let englishPart = modifiedMatch[match.startIndex..<index]
                let chinesePart = modifiedMatch[index...]
                modifiedMatch = "\(englishPart)<span style=\"font-family: 'Source Han Serif CN'; font-size: 13.5px; font-weight: 400; margin-left: 2px;\">\(chinesePart)</span>"
            }
            
            return modifiedMatch
        })
    }
    
    func replaceExclamation(_ input: String) -> String { // special style, tag
        let pattern = #"\!([^!]*)\!"#
        let baseTemplate = "<span style=\"font-family: Optima; color: white; font-size: 15px; font-weight: 600; font-variant: small-caps; background: #0072CF; border-radius: 4px 0 0 4px; display: inline-block; height: 16px; line-height: 15px; margin-right: 5px; padding: 0 2px 0 5px; position: relative; transform: translateY(-1px);\">$1<span style=\"width: 0; height: 0; position: absolute; top: 0; left: 100%; border-style: solid; border-width: 8px 0 8px 6px; border-color: transparent transparent transparent #0072CF;\"></span></span>"
        let template = String(format: invisibleTemplate, "!") + baseTemplate + String(format: invisibleTemplate, "!")
        return replacePattern(in: input, withRegexPattern: pattern, usingTemplate: template)
    }
    
    func replaceAtSign(_ input: String) -> String { // light blue without mark
        let pattern = "@([^@]*)@"
        let baseTemplate = "<span style=\"font-family: Bookerly; color: #0072CF; font-size: 15px; word-spacing: 0.1rem;\">$1</span>"
        let template = String(format: invisibleTemplate, "@") + baseTemplate + String(format: invisibleTemplate, "@")
        return replacePattern(in: input, withRegexPattern: pattern, usingTemplate: template, transform: { match in
            let modifiedMatch = match
                .replacingOccurrences(of: ",", with: "<span style=\"color: #DE002D;\">,</span>")
                .replacingOccurrences(of: "|", with: "<span style=\"color: #DE002D;\">|</span>")
            
            let pattern = #"\{([^}]*)\}"#
            let baseTemplate = "<span style=\"font-size: 13.5px;\">$1</span>" // smaller
            let template = String(format: invisibleTemplate, "{") + baseTemplate + String(format: invisibleTemplate, "}")
            
            let regex = try! NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(match.startIndex..<match.endIndex, in: match)
            return regex.stringByReplacingMatches(in: modifiedMatch, options: [], range: range, withTemplate: template)
        })
    }
    
    func replaceAndSign(_ input: String) -> String { // black Bookerly
        let pattern = "&([^&]*)&"
        let baseTemplate = "<span style=\"font-family: Bookerly; font-size: 15px; word-spacing: 0.1rem;\">$1</span>"
        let template = String(format: invisibleTemplate, "&") + baseTemplate + String(format: invisibleTemplate, "&")
        return replacePattern(in: input, withRegexPattern: pattern, usingTemplate: template, transform: { match in
            let pattern = #"\{([^}]*)\}"#
            let baseTemplate = "<span style=\"color: #007A6C; font-style: italic;\">$1</span>" // light green, italic
            let template = String(format: invisibleTemplate, "{") + baseTemplate + String(format: invisibleTemplate, "}")
            
            let regex = try! NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(match.startIndex..<match.endIndex, in: match)
            return regex.stringByReplacingMatches(in: match, options: [], range: range, withTemplate: template)
        })
    }
    
    func replaceCaretSign(_ input: String) -> String { // light green, chinese
        let pattern = #"\^([^^]*)\^"#
        let baseTemplate = "<span style=\"font-family: 'Source Han Serif CN'; color: #007A6C; font-size: 13.5px; word-spacing: 0.1rem; padding: 0 2px; margin-left: 2px; background: rgba(0, 122, 108, 0.2); border-radius: 3px;\">$1</span>"
        let template = String(format: invisibleTemplate, "^") + baseTemplate + String(format: invisibleTemplate, "^")
        return replacePattern(in: input, withRegexPattern: pattern, usingTemplate: template)
    }
    
    // Combine the input into a single message
    func generateMessage() {
        var modifiedSource = source
        var modifiedOriginalText = originalText
        var modifiedNotes = notes
        var modifiedTags = tags
        
        if wordPhrase != "" {
            modifiedSource = highlightWord(modifiedSource)
            modifiedOriginalText = highlightWord(modifiedOriginalText)
        }
        
        // Source
        modifiedSource = replacePlusSign(modifiedSource) // light blue
        
        // Original Text
        modifiedOriginalText = replaceAngleBrackets(modifiedOriginalText) // red
        modifiedOriginalText = replacePlusSign(modifiedOriginalText) // light blue
        modifiedOriginalText = replaceSquareBrackets(modifiedOriginalText) // green
        
        // Notes
        if notes != "" {
            modifiedNotes = replaceAngleBrackets(modifiedNotes) // red
            modifiedNotes = replacePOS(modifiedNotes)
            modifiedNotes = replaceSlash(modifiedNotes)
            modifiedNotes = replaceAtSign(modifiedNotes)
            modifiedNotes = replaceAndSign(modifiedNotes)
            modifiedNotes = replacePlusSign(modifiedNotes) // light blue
            modifiedNotes = replaceAsterisk(modifiedNotes)
            modifiedNotes = replaceCaretSign(modifiedNotes)
            modifiedNotes = replaceExclamation(modifiedNotes)
            modifiedNotes = replaceSquareBrackets(modifiedNotes) // green
        }
        
        let labelTemplate = "<span style=\"font-family: Bookerly; color: #4F7DC0; font-weight: 500;\">[%@]</span>" // median dark blue
        
        if notes != "" {
            modifiedNotes = "\n\n" + String(format: labelTemplate, "Notes") + " " + modifiedNotes
        }
        if tags != "" {
            modifiedTags = "\n\n" + "<span style=\"font-family: Bookerly;\">\(tags)</span>"
        }
        
        generatedMessage = """
        \(String(format: labelTemplate, "Source")) \(modifiedSource)
        
        \(String(format: labelTemplate, "Original Text"))
        
        \(modifiedOriginalText)\(modifiedNotes)\(modifiedTags)
        """
        
        generatedMessage = "<span style=\"font-family: Optima, Bookerly, 'Source Han Serif CN'; font-size: 16px;\">" + generatedMessage + "</span>"
        
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
