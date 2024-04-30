//
//  TrimPassageView.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/3/8.
//

import SwiftUI

struct TrimPassageView: View {
    @State private var originalPassage: String = ""
    @State private var trimmedPassage: String = ""
    @State private var trimmedCount: Int = 0
    
    private let replacements = ["(Traveler)'s": "Stella's",
                                "(Traveler)": "Stella",
                                "Traveler": "Stella",
                                "Icon Dialogue Talk": "(Option) Stella:",
                                "(sister/brother)": "brother"]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 15) {
                    VStack(alignment: .leading) {
                        Label("Original Passage:", systemImage: "note.text").foregroundColor(.brown)
                        CustomTextEditor(text: $originalPassage)
                        
                        Button(action: {
                            if let text = ClipboardManager.pasteFromClipboard() {
                                originalPassage = text
                                trimmedPassage = processPassage(input: originalPassage, replacements: replacements)
                                ClipboardManager.copyToClipboard(textToCopy: trimmedPassage)
                            }
                        }) {
                            Image(systemName: "doc.on.clipboard")
                            Text("Paste from Clipboard")
                        }
                    }
                    .padding(.bottom, 10)
                    
                    VStack(alignment: .leading) {
                        Label("Trimmed Passage:", systemImage: "note.text.badge.plus")
                            .foregroundColor(.purple)
                        CustomTextEditor(text: $trimmedPassage)
                        
                        HStack {
                            Button(action: {
                                ClipboardManager.copyToClipboard(textToCopy: trimmedPassage)
                            }) {
                                Image(systemName: "doc.on.doc")
                                Text("Copy to Clipboard")
                            }
                            Spacer()
                            Text("Trimmed Count: \(trimmedCount)")
                        }
                    }
                }
                .padding(.top, 5)
                
                Button(action: {
                    trimmedPassage = processPassage(input: originalPassage, replacements: replacements)
                    ClipboardManager.copyToClipboard(textToCopy: trimmedPassage)
                }) {
                    Image(systemName: "scissors").foregroundColor(.indigo)
                    Text("Trim Passage").foregroundColor(.indigo)
                }
                .position(x: geometry.size.width / 2 - 20, y: geometry.safeAreaInsets.top + 10)
            }
            .padding(.top, 5)
            .padding(.bottom)
            .padding(.leading)
            .padding(.trailing)
        }
    }
    
    func cleanText(_ input: String) -> String {
        // Start with built-in character sets for letters and decimal digits
        var allowedCharacterSet = CharacterSet.letters
        allowedCharacterSet.formUnion(CharacterSet.decimalDigits)
        
        // Define additional common punctuation and whitespace characters
        let additionalCharacters = "@#^&*+⇿⟨⟩<> ,.!?;:'\"()[]{}-–—_/\n\t"
        
        // Include these additional characters into the allowed set
        allowedCharacterSet.formUnion(CharacterSet(charactersIn: additionalCharacters))
        
        // Filter the input string to retain only characters in the allowed character set
        let filteredScalars = input.unicodeScalars.filter { allowedCharacterSet.contains($0) }
        let cleanedText = String(filteredScalars)
        
        // To correctly count invisible characters removed:
        // Convert both the original and cleaned text into their respective arrays of unicode scalars.
        let originalScalars = Array(input.unicodeScalars)
        let cleanedScalarsArray = Array(cleanedText.unicodeScalars)
        
        // Debugging: Calculate the number of characters removed
        trimmedCount = originalScalars.count - cleanedScalarsArray.count
        
        // Return the cleaned text
        return cleanedText
    }
    
    func processPassage(input: String, replacements: [String: String]) -> String {
        var modifiedInput = cleanText(input)
        
        // Step 1: Replace keywords based on the replacements dictionary
        for (keyword, replacement) in replacements {
            modifiedInput = modifiedInput.replacingOccurrences(of: keyword, with: replacement)
        }
        
        // Step 2: Split the modified input into lines and process each line
        let lines = modifiedInput.components(separatedBy: "\n")
        var processedLines: [String] = []
        
        for line in lines {
            // Trim invisible characters from both sides of the line
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            // Ignore empty lines
            if !trimmedLine.isEmpty {
                processedLines.append(trimmedLine)
            }
        }
        
        // Step 3: Join all processed lines with two newlines between each line
        let result = processedLines.joined(separator: "\n\n")
        return result
    }
}

#Preview {
    OptionsView()
}
