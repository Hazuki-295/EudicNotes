//
//  CombineNotesView.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/3/8.
//

import SwiftUI

struct SingleNotesView: View {
    @Binding var noteText: String
    var label: String
    var systemImage: String
    var labelColor: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            Label(label, systemImage: systemImage)
                .foregroundColor(labelColor)
            CustomTextEditor(text: $noteText, minWidth: 480)
            HStack {
                Button(action: {
                    if let text = ClipboardManager.pasteFromClipboard() {
                        noteText = text
                    }
                }) {
                    Image(systemName: "doc.on.clipboard")
                    Text("Paste")
                }
                Spacer()
                Button(action: { noteText = "" }) {
                    Image(systemName: "eraser.line.dashed")
                    Text("Clear")
                }
            }
        }
    }
}

struct CombineNotesView: View {
    @State private var note1: String = ""
    @State private var note2: String = ""
    @State private var note3: String = ""
    @State private var note4: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            SingleNotesView(noteText: $note1, label: "First Notes", systemImage: "note.text", labelColor: .brown)
            SingleNotesView(noteText: $note2, label: "Second Notes", systemImage: "2.square", labelColor: .purple)
            SingleNotesView(noteText: $note3, label: "Third Notes", systemImage: "3.square", labelColor: .blue)
            SingleNotesView(noteText: $note4, label: "Fourth Notes", systemImage: "4.square", labelColor: .red)
        }
        .padding()
    }
}

#Preview {
    OptionsView()
}
