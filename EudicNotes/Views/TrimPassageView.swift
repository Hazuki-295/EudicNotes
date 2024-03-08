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
        VStack(alignment: .leading, spacing: 10) {
            Label("Original Passage:", systemImage: "note.text").foregroundColor(.brown)
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
                    Text("Paste")
                }
                Button(action: {
                    trimedPassage = processPassage(input: originalPassage, replacements: replacements)
                    ClipboardManager.copyToClipboard(textToCopy: trimedPassage)
                }) {
                    Image(systemName: "scissors").foregroundColor(.indigo)
                    Text("Trim Passage").foregroundColor(.indigo)
                }
            }
            
            Label("Trimed Passage:", systemImage: "note.text.badge.plus")
                .foregroundColor(.purple)
                .padding(.top, 10)
            CustomTextEditor(text: $trimedPassage)
            
            Button(action: {
                ClipboardManager.copyToClipboard(textToCopy: trimedPassage)
            }) {
                Image(systemName: "doc.on.doc")
                Text("Copy to Clipboard")
            }
        }
        .padding(.top, 5)
        .padding(.bottom)
        .padding(.leading)
        .padding(.trailing)
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
