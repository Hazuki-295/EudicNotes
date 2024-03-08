//
//  ContentView.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/3/6.
//

import SwiftUI

struct ContentView: View {
    private let width: CGFloat = 600
    private let height: CGFloat = 700
    
    var body: some View {
        MainView()
            .frame(minWidth: width, maxWidth: width,
                   minHeight: height, maxHeight: height)
    }
}

#Preview {
    ContentView()
}
