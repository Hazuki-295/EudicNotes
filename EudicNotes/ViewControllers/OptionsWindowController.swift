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
        if let existingWindow = optionsWindow {
            existingWindow.makeKeyAndOrderFront(nil) // Bring the existing window to the front
        } else {
            let optionsView = OptionsView().environmentObject(sharedNoteData) // SwiftUI view
            let hostingController = NSHostingController(rootView: optionsView)
            
            // Create the window with the hosting controller
            let window = NSWindow(contentViewController: hostingController)
            window.makeKeyAndOrderFront(nil)
            window.title = "Options"
            
            // Keep a reference to the newly created window
            self.optionsWindow = window
            
            // Set up for window close detection
            window.isReleasedWhenClosed = false
            window.delegate = self
        }
    }
    
    func windowWillClose(_ notification: Notification) {
        optionsWindow = nil // Release the window when it's closed
    }
}
