//
//  CombineNotesView.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/3/8.
//

import SwiftUI
import WebKit

struct CombineNotesView: View {
    @StateObject private var sharedNoteData = NoteData()
    @StateObject private var CombinedNoteData = NoteData()
    
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
            }
            
            SingleNoteView(noteData: CombinedNoteData, label: "Combined Notes", labelColor: .corenlp)
            SingleNoteView(noteData: sharedNoteData, enableHistory: true, label: "Single NoteData Preview", labelColor: .oaldBlue)
                .frame(height: 350)
            
        }
        .padding(.top, 5)
        .padding(.bottom)
        .padding(.leading)
        .padding(.trailing)
    }
}

struct CombineNotesView_Previews: PreviewProvider {
    static var previews: some View {
        previewOptionsView()
    }
}
