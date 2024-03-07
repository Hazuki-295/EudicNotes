//
//  ComboBox.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/3/7.
//

import SwiftUI

struct ComboBox: View {
    @Binding var text: String
    var options: [String]
    @State private var isPickerVisible = false
    
    var body: some View {
        HStack {
            ZStack {
                HStack{
                    Text("Source:")
                    TextField("Enter Source", text: $text)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .opacity(isPickerVisible ? 0 : 1)
                
                Picker("Source:", selection: $text) {
                    Text("None").tag("")
                    ForEach(options, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .opacity(isPickerVisible ? 1 : 0)
                .onChange(of: text) {
                    withAnimation {
                        isPickerVisible = false
                    }
                }
            }
            
            Button(action: {
                withAnimation {
                    isPickerVisible.toggle()
                }
            }) {
                Image(systemName: "chevron.down")
                    .rotationEffect(.degrees(isPickerVisible ? 180 : 0))
            }
        }
    }
}
