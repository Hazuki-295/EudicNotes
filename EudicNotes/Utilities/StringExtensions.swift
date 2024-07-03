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
                    applyToFirstMatchOnly: Bool = false,
                    transform: ((String) -> String)? = nil) -> String {
    do {
        // Compile the regular expression
        let regex = try NSRegularExpression(pattern: regexPattern, options: regexOptions)
        let nsRange = NSRange(input.startIndex..<input.endIndex, in: input)
        
        // Find matches
        let matches = regex.matches(in: input, options: [], range: nsRange)
        if matches.isEmpty { return input }
        
        // If only applying to the first match, limit matches array
        let matchesToProcess = applyToFirstMatchOnly ? Array(matches.prefix(1)) : matches.reversed()
        
        // Convert input to NSMutableString for in-place modifications
        let resultString = NSMutableString(string: input)
        
        // Process each match
        for match in matchesToProcess {
            var currentReplacement = replacementTemplate
            
            // Replace placeholders in the template with transformed substrings
            for groupIndex in 0..<match.numberOfRanges {
                let groupRange = match.range(at: groupIndex)
                if groupRange.location != NSNotFound, groupRange.length > 0 {
                    let matchedSubstring = (input as NSString).substring(with: groupRange)
                    let transformedSubstring = transform?(matchedSubstring) ?? matchedSubstring
                    currentReplacement = currentReplacement.replacingOccurrences(of: "$\(groupIndex)", with: transformedSubstring)
                }
            }
            
            // Apply the replacement
            resultString.replaceCharacters(in: match.range, with: currentReplacement)
        }
        
        return resultString as String
    } catch {
        print("Regex error: \(error.localizedDescription)")
        return input
    }
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
        let template = revert ? "$1" : #"<span class="highlight blue">$1</span>"# // blue
        return replacePattern(in: self, withRegexPattern: pattern, usingTemplate: template)
    }
    
    func replaceSquareBrackets(revert: Bool = false) -> String {
        let pattern = #"\[([^]]*)\]"#
        let template = revert ? "$1" : #"<span class="highlight green">$1</span>"# // green
        return replacePattern(in: self, withRegexPattern: pattern, usingTemplate: template)
    }
    
    func replaceAngleBrackets(revert: Bool = false) -> String {
        let pattern = "<([^>]*)>"
        let template = revert ? "$1" : #"<span class="highlight red">$1</span>"# // red
        return replacePattern(in: self, withRegexPattern: pattern, usingTemplate: template)
    }
    
    // 2. LDOCE Style
    func replacePOS() -> String {
        var modifiedText = self
        
        let replacements: [(pattern: String, template: String)] = [
            (#"\b(noun|verb|adjective|adverb|preposition|conjunction|pronoun)\b"#, #"<span class="lm5pp_POS" dict="lm5pp">$1</span>"#),
            (#"\b(Phrasal Verb)\b"#, #"<span class="lm5pp_POS phr" dict="lm5pp">$1</span>"#),
            (#"\b(Idioms)\b"#, #"<span class="idiom" dict="oald">$1</span>"#)
        ]
        
        replacements.forEach { pattern, template in
            modifiedText = replacePattern(in: modifiedText, withRegexPattern: pattern, usingTemplate: template, applyToFirstMatchOnly: true)
        }
        
        return modifiedText
    }
    
    func replaceSlash() -> String {
        let pattern = #"(?<![<A-Za-z.])/[A-Za-z.-]+(\s+[A-Za-z.-]+)*"# // not inside </span>, not words that separated by '/'
        let template = #"<span class="ACTIV" dict="lm5pp">$0</span>"#
        return replacePattern(in: self, withRegexPattern: pattern, usingTemplate: template)
    }
    
    // 3. OALD Style
    func replaceAsterisk() -> String {
        let pattern = #"\*([^*]*)\*"#
        let template = #"<span class="shcut" dict="oald">$1</span>"#
        return replacePattern(in: self, withRegexPattern: pattern, usingTemplate: template, transform: { match in
            var modifiedMatch = match
            
            if let index = modifiedMatch.firstIndex(where: { $0.isCJK }) {
                let englishPart = modifiedMatch[match.startIndex..<index]
                let chinesePart = modifiedMatch[index...]
                modifiedMatch = #"\#(englishPart)<span class="OALECD_chn" dict="oald">\#(chinesePart)</span>"#
            }
            
            return modifiedMatch
        })
    }
    
    func replaceExclamation() -> String {
        let pattern = #"\!([^!]*)\!"#
        let template = #"<span class="prefix" dict="oald">$1</span>"#
        return replacePattern(in: self, withRegexPattern: pattern, usingTemplate: template)
    }
    
    func replaceAtSign() -> String {
        let pattern = "@([^@]*)@"
        let template = #"<span class="cf" dict="oald">$1</span>"#
        return replacePattern(in: self, withRegexPattern: pattern, usingTemplate: template, transform: { match in
            var modifiedMatch = match
                .replacingOccurrences(of: "$sep$", with: #"<span class="sep" dict="oald">,</span>"#)
            
            let replacements: [String: String] = [
                "⟨([^⟩]*)⟩": #"<span class="reg" dict="oald">$0</span>"#, // smaller
                "_([^_]*)_": #"<span class="geo" dict="oald">$1</span>"# // green
            ]
            
            for (pattern, template) in replacements {
                modifiedMatch = replacePattern(in: modifiedMatch, withRegexPattern: pattern, usingTemplate: template)
            }
            
            return modifiedMatch
        })
    }
    
    func replaceAndSign() -> String {
        let pattern = "&([^&]*)&"
        let template = #"<span class="def" dict="oald">$1</span>"#
        return replacePattern(in: self, withRegexPattern: pattern, usingTemplate: template, transform: { match in
            var modifiedMatch = match
            
            let replacements: [String: String] = [
                #"\{([^}]*)\}"#: #"<span class="ndv" dict="oald">$1</span>"# // green, italic
            ]
            
            for (pattern, template) in replacements {
                modifiedMatch = replacePattern(in: modifiedMatch, withRegexPattern: pattern, usingTemplate: template)
            }
            
            if let index = modifiedMatch.firstIndex(where: { $0.isCJK }) {
                let englishPart = modifiedMatch[match.startIndex..<index]
                let chinesePart = modifiedMatch[index...]
                modifiedMatch = #"\#(englishPart)<span class="OALECD_chn" dict="oald">\#(chinesePart)</span>"#
            }
            
            return modifiedMatch
        })
    }
    
    func collapseWhitespace() -> String {
        return self.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}
