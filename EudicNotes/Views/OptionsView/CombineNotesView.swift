//
//  CombineNotesView.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/3/8.
//

import SwiftUI
import WebKit

struct CombineNotesView: View {
    @StateObject private var noteData1 = NoteData()
    @StateObject private var noteData2 = NoteData()
    
    @State private var combinedNotes: String = ""
    
    var body: some View {
        VStack(alignment: .center) {
            HStack {
                Button(action: {}) {
                    Image(systemName: "list.clipboard").foregroundColor(.purple)
                    Text("Retrieve Clipboard").foregroundColor(.purple)
                }
                Button(action: {}) {
                    Image(systemName: "book").foregroundColor(.indigo)
                    Text("Combine Notes").foregroundColor(.indigo)
                }
                Button(action: { noteData1.clearFields(); noteData2.clearFields() }) {
                    Image(systemName: "eraser.line.dashed")
                    Text("Clear All")
                }
            }
            
            SingleNoteView(label: "First Notes", labelColor: .brown, systemImage: "note.text", noteData: noteData1)
            SingleNoteView(label: "Second Notes", labelColor: .purple, systemImage: "2.square", noteData: noteData2)
            
        }
        .padding(.top, 5)
        .padding(.bottom)
        .padding(.leading)
        .padding(.trailing)
    }
}

#Preview {
    OptionsView()
}
