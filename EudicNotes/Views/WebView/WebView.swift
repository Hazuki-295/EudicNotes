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
    var baseURL: URL?
    
    private static let logger = Logger(subsystem: "EudicNote.WebView")
    
    func makeNSView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        if context.coordinator.didInitialLoad && !nsView.isLoading {
            if context.coordinator.lastLoadedContent != htmlContent {
                nsView.loadHTMLString(self.htmlContent, baseURL: self.baseURL)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        var didInitialLoad = false
        var lastLoadedContent: String = ""
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            didInitialLoad = true
            
            if let js = parent.initialJsToExecute {
                parent.webView.executeJavaScript(js: js, verbose: false)
            }
            
            // Fetch and update the HTML content
            lastLoadedContent = parent.htmlContent
        }
    }
}

extension WKWebView {
    private static let logger = Logger(subsystem: "EudicNote.WebView")
    
    func executeJavaScript(js: String, verbose: Bool = true, completion: ((Any?, Error?) -> Void)? = nil) {
        self.evaluateJavaScript(js) { result, error in
            if verbose {
                if let error = error {
                    WKWebView.logger.error("JavaScript execution error: \(error.localizedDescription)")
                }
                let resultDescription = result.map { String(describing: $0) } ?? "nil"
                WKWebView.logger.info("JavaScript execution result: \(resultDescription)")
            }
            completion?(result, error)
        }
    }
    
    static func clearWebCache() {
        WKWebsiteDataStore.default().removeData(
            ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
            modifiedSince: Date(timeIntervalSince1970: 0),
            completionHandler: { WKWebView.logger.info("Web cache cleared.") }
        )
    }
}
