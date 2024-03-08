//
//  TrimPassageView.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/3/8.
//

import SwiftUI

struct TrimPassageView: View {
    @State private var originalPassage: String = ""
    @State private var trimedPassage: String = ""
    
    private let replacements = ["Traveler": "Stella",
                                "(Traveler)": "Stella",
                                "Icon Dialogue Talk": "(Option) Stella:"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Label("Original Passage:", systemImage: "book.pages")
            CustomTextEditor(text: $originalPassage)
            
            HStack {
                Button(action: {
                    if let text = ClipboardManager.pasteFromClipboard() {
                        originalPassage = text
                        trimedPassage = processPassage(input: originalPassage, replacements: replacements)
                        ClipboardManager.copyToClipboard(textToCopy: trimedPassage)
                    }
                }) {
                    Image(systemName: "doc.on.clipboard")
                    HStack {
                        Text("Paste from Clipboard")
                    }
                }
                Button(action: {
                    trimedPassage = processPassage(input: originalPassage, replacements: replacements)
                    ClipboardManager.copyToClipboard(textToCopy: trimedPassage)
                }) {
                    Image(systemName: "crop")
                    HStack {
                        Text("Trim Passage")
                    }
                }
            }
            
            Label("Trimed Passage:", systemImage: "wand.and.stars").padding(.top, 20)
            CustomTextEditor(text: $trimedPassage, minHeight: 200)
            
            Button(action: {
                ClipboardManager.copyToClipboard(textToCopy: trimedPassage)
            }) {
                Image(systemName: "doc.on.doc")
                HStack {
                    Text("Copy to Clipboard")
                }
            }
        }
        .padding()
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
