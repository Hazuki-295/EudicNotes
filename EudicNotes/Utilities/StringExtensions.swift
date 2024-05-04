//
//  StringExtensions.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/5/4.
//

import Foundation

// Generalized function to replace patterns in a string
func replacePattern(in input: String, withRegexPattern regexPattern: String,
                    usingTemplate replacementTemplate: String, options regexOptions: NSRegularExpression.Options = [],
                    transform: ((String) -> String)? = nil) -> String {
    do {
        // Compile the regular expression based on the provided pattern and options
        let regex = try NSRegularExpression(pattern: regexPattern, options: regexOptions)
        let range = NSRange(input.startIndex..<input.endIndex, in: input)
        let nsInput = input as NSString
        let resultString = NSMutableString(string: nsInput)
        
        // Find all matches and process them in reverse order to preserve indices for replacements
        let matches = regex.matches(in: input, options: [], range: range).reversed()
        for match in matches {
            // Process each capturing group within the match
            var currentReplacement = replacementTemplate
            for groupIndex in 0..<match.numberOfRanges {
                let groupRange = match.range(at: groupIndex)
                if groupRange.location != NSNotFound, groupRange.length != 0 {
                    let matchedSubstring = nsInput.substring(with: groupRange)
                    // Apply any provided transformation to the matched substring
                    let transformedSubstring = transform?(matchedSubstring) ?? matchedSubstring
                    // Replace the placeholder corresponding to the current group index
                    currentReplacement = currentReplacement.replacingOccurrences(of: "$\(groupIndex)", with: transformedSubstring, options: .literal, range: nil)
                }
            }
            // Apply the final replacement to the result string
            resultString.replaceCharacters(in: match.range, with: currentReplacement)
        }
        
        return resultString as String
    } catch {
        print("Regex error: \(error.localizedDescription)")
        return input
    }
}

private func invisibleTemplate(_ firstChar: Character, middleString: String, _ lastChar: Character) -> String {
    let template = "<span style=\"opacity: 0; position: absolute;\">%@</span>"
    return String(format: template, String(firstChar)) + "\(middleString)" + String(format: template, String(lastChar))
}

extension String {
    // 1. Colorful fonts
    func highlightWord(_ wordPhrase: String) -> String {
        let pattern = "\\b\(wordPhrase)\\b"
        let template = "+$0+"
        return replacePattern(in: self, withRegexPattern: pattern, usingTemplate: template, options: .caseInsensitive)
    }
    
    func replacePlusSign(revert: Bool = false) -> String {
        let pattern = #"\+([^+]*)\+"#
        let baseTemplate = "<span style=\"color: #35A3FF; font-weight: bold;\">$1</span>" // light blue
        let template = revert ? "$1" : invisibleTemplate("+", middleString: baseTemplate, "+")
        return replacePattern(in: self, withRegexPattern: pattern, usingTemplate: template)
    }
    
    func replaceSquareBrackets(revert: Bool = false) -> String {
        let pattern = #"\[([^]]*)\]"#
        let baseTemplate = "<span style=\"color: #67A78A; font-weight: bold;\">$1</span>" // green
        let template = revert ? "$1" : invisibleTemplate("[", middleString: baseTemplate, "]")
        return replacePattern(in: self, withRegexPattern: pattern, usingTemplate: template)
    }
    
    func replaceAngleBrackets(revert: Bool = false) -> String {
        let pattern = "<([^>]*)>"
        let baseTemplate = "<span style=\"color: #F51225; font-weight: bold\">$1</span>" // red
        let template = revert ? "$1" : invisibleTemplate("<", middleString: baseTemplate, ">")
        return replacePattern(in: self, withRegexPattern: pattern, usingTemplate: template)
    }
    
    // 2. LDOCE Style
    func replacePOS() -> String { // special style, dark red
        let replacements: [String: String] = [
            #"\b(noun|verb|adjective|adverb|preposition|conjunction|pronoun)\b"#: "<span style=\"font-family: Georgia; color: rgba(196, 21, 27, 0.8); font-size: 85%; font-weight: bold; font-style: italic; margin: 0 2px;\">$1</span>",
            #"\b(Phrasal Verb)\b"#: "<span style=\"font-family: Optima; color: rgba(196, 21, 27, 0.8); font-size: 74%; border: 1px solid rgba(196, 21, 27, 0.8); padding: 0px 3px; margin: 0 2px;\">$1</span>",
            #"\b(Idioms)\b"#: "<span style=\"font-family: Optima; color: #0072CF; font-size: 15px; font-weight: 600; word-spacing: 0.1rem; margin: 0 2px;\">$1</span>"
        ]
        
        var modifiedInput = self
        for (pattern, template) in replacements {
            modifiedInput = replacePattern(in: modifiedInput, withRegexPattern: pattern, usingTemplate: template)
        }
        return modifiedInput
    }
    
    func replaceSlash() -> String { // special style, hotpink
        let pattern = #"(?<![<A-Za-z.])/[A-Za-z.]+(?:\s+[A-Za-z.]+)*"#
        let template = "<span style=\"font-family: Optima; color: hotpink; font-size: 80%; font-weight: bold; text-transform: uppercase; margin: 0px 2px;\">$0</span>"
        return replacePattern(in: self, withRegexPattern: pattern, usingTemplate: template)
    }
    
    // 3. OALD Style
    func replaceAsterisk() -> String { // special style, light blue with mark
        let pattern = #"\*([^*]*)\*"#
        let baseTemplate = "<span style=\"font-family: Optima; color: #0072CF; font-size: 15px; font-weight: 600; word-spacing: 0.1rem; background: linear-gradient(to bottom, rgba(0, 114, 207, 0) 55%, rgba(0, 114, 207, 0.15) 55%, rgba(0, 114, 207, 0.15) 100%); margin: 0 2px; padding-right: 3.75px\">$1</span>"
        let template = invisibleTemplate("*", middleString: baseTemplate, "*")
        
        return replacePattern(in: self, withRegexPattern: pattern, usingTemplate: template, transform: { match in
            var modifiedMatch = match
                .replacingOccurrences(of: ",", with: "<span style=\"color: #DE002D;\">,</span>")
                .replacingOccurrences(of: "⇿", with: "<span style=\"color: #DE002D;\">⇿</span>")
            
            if let index = modifiedMatch.firstIndex(where: { $0.isCJK }) {
                let englishPart = modifiedMatch[match.startIndex..<index]
                let chinesePart = modifiedMatch[index...]
                modifiedMatch = "\(englishPart)<span style=\"font-family: 'Source Han Serif CN'; font-size: 13.5px; font-weight: 400; margin-left: 2px;\">\(chinesePart)</span>"
            }
            
            return modifiedMatch
        })
    }
    
    func replaceExclamation() -> String { // special style, tag
        let pattern = #"\!([^!]*)\!"#
        let baseTemplate = "<span style=\"font-family: Optima; color: white; font-size: 15px; font-weight: 600; font-variant: small-caps; background: #0072CF; border-radius: 4px 0 0 4px; display: inline-block; height: 16px; line-height: 15px; margin-right: 5px; padding: 0 2px 0 5px; position: relative; transform: translateY(-1px);\">$1<span style=\"width: 0; height: 0; position: absolute; top: 0; left: 100%; border-style: solid; border-width: 8px 0 8px 6px; border-color: transparent transparent transparent #0072CF;\"></span></span>"
        let template = invisibleTemplate("!", middleString: baseTemplate, "!")
        return replacePattern(in: self, withRegexPattern: pattern, usingTemplate: template)
    }
    
    func replaceAtSign() -> String { // light blue without mark
        let pattern = "@([^@]*)@"
        let baseTemplate = "<span style=\"font-family: Bookerly; color: #0072CF; font-size: 15px; word-spacing: 0.1rem;\">$1</span>"
        let template = invisibleTemplate("@", middleString: baseTemplate, "@")
        return replacePattern(in: self, withRegexPattern: pattern, usingTemplate: template, transform: { match in
            var modifiedMatch = match
                .replacingOccurrences(of: "{,}", with: "<span style=\"color: #DE002D;\">,</span>")
                .replacingOccurrences(of: "|", with: "<span style=\"color: #DE002D;\">|</span>")
            
            let replacements: [String: String] = [
                "⟨([^⟩]*)⟩": "<span style=\"font-size: 13.5px;\">$0</span>", // smaller
                #"\{([^}]*)\}"#: invisibleTemplate("{", middleString: "<span style=\"font-style: italic;\">$1</span>", "}") // italic
            ]
            
            for (pattern, template) in replacements {
                modifiedMatch = replacePattern(in: modifiedMatch, withRegexPattern: pattern, usingTemplate: template)
            }
            
            return modifiedMatch
        })
    }
    
    func replaceAndSign() -> String { // black Bookerly
        let pattern = "&([^&]*)&"
        let baseTemplate = "<span style=\"font-family: Bookerly; font-size: 15px; word-spacing: 0.1rem;\">$1</span>"
        let template = invisibleTemplate("&", middleString: baseTemplate, "&")
        return replacePattern(in: self, withRegexPattern: pattern, usingTemplate: template, transform: { match in
            let pattern = #"\{([^}]*)\}"#
            let baseTemplate = "<span style=\"color: #007A6C; font-style: italic;\">$1</span>" // light green, italic
            let template = invisibleTemplate("{", middleString: baseTemplate, "}")
            return replacePattern(in: match, withRegexPattern: pattern, usingTemplate: template)
        })
    }
    
    func replaceCaretSign() -> String { // light green, chinese
        let pattern = #"\^([^^]*)\^"#
        let baseTemplate = "<span style=\"font-family: 'Source Han Serif CN'; color: #007A6C; font-size: 13.5px; word-spacing: 0.1rem; padding: 0 2px; margin-left: 2px; background: rgba(0, 122, 108, 0.2); border-radius: 3px;\">$1</span>"
        let template = invisibleTemplate("^", middleString: baseTemplate, "^")
        return replacePattern(in: self, withRegexPattern: pattern, usingTemplate: template)
    }
}
