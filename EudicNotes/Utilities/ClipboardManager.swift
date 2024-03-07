//
//  ClipboardManager.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/3/8.
//

import AppKit

class ClipboardManager {
    static func copyToClipboard(textToCopy: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(textToCopy, forType: .string)
    }
    
    static func pasteFromClipboard() -> String? {
        let pasteboard = NSPasteboard.general
        return pasteboard.string(forType: .string)
    }
}
