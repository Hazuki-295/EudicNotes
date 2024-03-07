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
    
    func openOptionsWindow() {
        if let existingWindow = optionsWindow {
            existingWindow.makeKeyAndOrderFront(nil) // Bring the existing window to the front
        } else {
            let optionsView = OptionsView()
            let hostingController = NSHostingController(rootView: optionsView)
            
            let window = NSWindow(contentViewController: hostingController)
            window.setContentSize(NSSize(width: 480, height: 300)) // Set your desired window size
            window.makeKeyAndOrderFront(nil)
            window.center() // Center the window on the screen
            window.title = "Options"
            
            self.optionsWindow = window
            
            window.isReleasedWhenClosed = false
            window.delegate = self // Set the window delegate to self
        }
    }
    
    func windowWillClose(_ notification: Notification) {
        optionsWindow = nil // Release the window when it's closed
    }
}
