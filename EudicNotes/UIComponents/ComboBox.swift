//
//  ComboBox.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/3/7.
//

import SwiftUI

struct ComboBox: View {
    let label: String
    @Binding var text: String
    let options: [String]
    
    @State private var isPickerVisible = false
    
    var body: some View {
        HStack {
            if isPickerVisible {
                Picker("\(label):", selection: $text) {
                    Text("None").tag("")
                    ForEach(options, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .onChange(of: text) { withAnimation { isPickerVisible = false } }
                .frame(height: 20)
            } else {
                Text("\(label):")
                TextField("Enter \(label)", text: $text)
                    .textFieldStyle(.roundedBorder)
                    .frame(height: 20)
            }
            
            Button(action: { withAnimation { isPickerVisible.toggle() } }) {
                Image(systemName: "chevron.down")
                    .rotationEffect(.degrees(isPickerVisible ? 180 : 0))
            }
        }
    }
}
