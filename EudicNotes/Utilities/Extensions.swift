//
//  Extensions.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/5/4.
//

import Foundation
import SwiftUI

extension Color {
    init(hexString: String, opacity: Double = 1.0) {
        // Remove the hash if it exists
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        
        // Ensure it's valid
        guard hex.count == 6 else {
            self.init(.sRGB, red: 0, green: 0, blue: 0, opacity: opacity)
            return
        }
        
        // Convert to integer
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        
        let red = Double((int & 0xff0000) >> 16) / 255.0
        let green = Double((int & 0xff00) >> 8) / 255.0
        let blue = Double(int & 0xff) / 255.0
        
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
    
    // CoreNLP annotator color
    static let corenlp = Color(hexString: "#AA1D36")
    
    // OALD style colors
    static let oaldRed = Color(hexString: "#DE002D")
    static let oaldGreen = Color(hexString: "#007A6C")
    static let oaldBlue = Color(hexString: "#0072CF")
}
