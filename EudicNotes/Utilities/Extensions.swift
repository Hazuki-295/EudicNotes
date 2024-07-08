//
//  Extensions.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/5/4.
//

import Foundation
import SwiftUI

extension String {
    func replacePattern(in input: String, withRegexPattern regexPattern: String, usingTemplate replacementTemplate: String, options regexOptions: NSRegularExpression.Options = []) -> String {
        let regex = try! NSRegularExpression(pattern: regexPattern, options: regexOptions)
        let nsRange = NSRange(input.startIndex..<input.endIndex, in: input)
        return regex.stringByReplacingMatches(in: input, options: [], range: nsRange, withTemplate: replacementTemplate)
    }
    
    func removePlusSign() -> String {
        let pattern = #"\+([^+]*)\+"#
        let template = "$1"
        return replacePattern(in: self, withRegexPattern: pattern, usingTemplate: template)
    }
    
    func removeSquareBrackets() -> String {
        let pattern = #"\[([^]]*)\]"#
        let template = "$1"
        return replacePattern(in: self, withRegexPattern: pattern, usingTemplate: template)
    }
    
    func removeAngleBrackets() -> String {
        let pattern = "<([^>]*)>"
        let template = "$1"
        return replacePattern(in: self, withRegexPattern: pattern, usingTemplate: template)
    }
    
    func collapseWhitespace() -> String {
        return self.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}

extension Character {
    // Check if the character is a CJK character
    var isCJK: Bool {
        return "\u{4E00}" <= self && self <= "\u{9FFF}" || // CJK Unified Ideographs
        "\u{3000}" <= self && self <= "\u{303F}" || // CJK Symbols and Punctuation
        "\u{FF00}" <= self && self <= "\u{FFEF}"    // Full-width ASCII + Half-width Katakana + Full-width symbols and punctuation
    }
}

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
}
