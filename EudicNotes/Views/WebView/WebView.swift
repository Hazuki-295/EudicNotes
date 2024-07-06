//
//  WebView.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/7/6.
//

import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
    @Binding var htmlContent: String
    var webView: WKWebView // Maintains session state across updates
    var initialJsToExecute: String? // Optional property for JavaScript to execute once
    
    private static let logger = Logger(subsystem: "EudicNote.WebView")
    
    func makeNSView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        if !context.coordinator.didInitialLoad {
            // Load HTML content initially
            nsView.loadHTMLString(htmlContent, baseURL: nil)
        } else {
            // Only update HTML content if it has changed
            nsView.evaluateJavaScript("document.documentElement.outerHTML") { result, error in
                if let currentHTML = result as? String, currentHTML != self.htmlContent {
                    nsView.loadHTMLString(self.htmlContent, baseURL: nil)
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Public method to allow JavaScript execution from parent view
    func executeJavaScript(js: String, verbose: Bool = true, completion: ((Result<Any?, Error>) -> Void)? = nil) {
        webView.evaluateJavaScript(js) { result, error in
            if let error = error {
                verbose ? WebView.logger.error("JavaScript execution error: \(error.localizedDescription)") : nil
                completion?(.failure(error))
            } else {
                if verbose {
                    let resultDescription = result.map { String(describing: $0) } ?? "nil"
                    WebView.logger.info("JavaScript execution result: \(resultDescription)")
                }
                completion?(.success(result))
            }
        }
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        var didInitialLoad = false
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if let js = parent.initialJsToExecute {
                parent.executeJavaScript(js: js, verbose: false)
            }
            
            // Fetch and update the HTML content
            webView.evaluateJavaScript("document.documentElement.outerHTML") { result, error in
                if let html = result as? String {
                    self.parent.htmlContent = html
                }
            }
            
            didInitialLoad = true
        }
    }
}
