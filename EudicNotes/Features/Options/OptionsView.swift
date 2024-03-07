//
//  OptionsView.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/3/7.
//

import SwiftUI

struct OptionsView: View {
    @State private var originalMessage: String = ""
    @State private var generatedMessage: String = ""
    
    private let replacements = ["Traveler": "Stella",
                                "(Traveler)": "Stella",
                                "Icon Dialogue Talk": "(Option) Stella:"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Original Message:")
            TextEditor(text: $originalMessage)
                .frame(minWidth: 500, maxWidth: 550,
                       minHeight: 200, maxHeight: 275)
                .lineSpacing(2)
                .padding(5)
                .background(Color.white)
                .cornerRadius(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.gray, lineWidth: 1)
                )
            HStack {
                Button("Paste from Clipboard") {
                    if let text = ClipboardManager.pasteFromClipboard() {
                        originalMessage = text
                        generatedMessage = processPassage(input: originalMessage, replacements: replacements)
                        ClipboardManager.copyToClipboard(textToCopy: generatedMessage)
                    }
                }
                Button("Format Message") {
                    generatedMessage = processPassage(input: originalMessage, replacements: replacements)
                    ClipboardManager.copyToClipboard(textToCopy: generatedMessage)
                }
            }
            
            Text("Generated Message:").padding(.top, 10)
            TextEditor(text: $generatedMessage)
                .frame(minWidth: 500, maxWidth: 550,
                       minHeight: 200, maxHeight: 275)
                .lineSpacing(2)
                .padding(5)
                .background(Color.white)
                .cornerRadius(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.gray, lineWidth: 1)
                )
            Button("Copy to Clipboard") {
                ClipboardManager.copyToClipboard(textToCopy: generatedMessage)
            }
        }
        .padding()
        .padding(.top, 10)
        .padding(.bottom, 15)
    }
    
    func processPassage(input: String, replacements: [String: String]) -> String {
        // Step 1: Replace keywords based on the replacements dictionary
        var modifiedInput = input
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
