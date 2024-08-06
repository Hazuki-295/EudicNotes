//
//  AppDelegate.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/3/7.
//

import AppKit
import SwiftUI

class OptionsWindowController: NSObject, NSWindowDelegate {
    private var optionsWindow: NSWindow?
    
    func openOptionsWindow(sharedNoteData: NoteData) {
        if optionsWindow == nil {
            let optionsView = OptionsView().environmentObject(sharedNoteData).preferredColorScheme(.light) // Enforce light mode
            let hostingController = NSHostingController(rootView: optionsView)
            optionsWindow = NSWindow(contentViewController: hostingController)
            optionsWindow?.title = "Options"
            optionsWindow?.isReleasedWhenClosed = false
            optionsWindow?.delegate = self
        }
        optionsWindow?.makeKeyAndOrderFront(nil)
    }
    
    func windowWillClose(_ notification: Notification) {
        optionsWindow = nil
    }
}
