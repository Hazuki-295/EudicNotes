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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Original Message:")
            TextEditor(text: $originalMessage)
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
                Button("Paste from Clipboard") {
                    if let text = ClipboardManager.pasteFromClipboard() {
                        originalMessage = text
                        // formatMessage()
                    }
                    
                }
                Button("Format Message") {
                    // formatMessage()
                    ClipboardManager.copyToClipboard(textToCopy: generatedMessage)
                }
            }
            
            Text("Generated Message:").padding(.top, 10)
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
            Button("Copy to Clipboard") {
                ClipboardManager.copyToClipboard(textToCopy: generatedMessage)
            }
        }
        .padding()
        .padding(.top, 10)
        .padding(.bottom, 10)
    }
}

#Preview {
    OptionsView()
}
