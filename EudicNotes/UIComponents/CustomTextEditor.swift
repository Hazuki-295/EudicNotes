//
//  CustomTextEditor.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/3/8.
//

import SwiftUI

struct CustomTextEditor: View {
    @Binding var text: String
    
    var body: some View {
        TextEditor(text: $text)
            .lineSpacing(2)
            .padding(5)
            .background(Color.white)
            .cornerRadius(5)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.gray, lineWidth: 1)
            )
    }
}
