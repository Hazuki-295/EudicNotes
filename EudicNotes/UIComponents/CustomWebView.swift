//
//  CustomWebView.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/5/6.
//

import SwiftUI
import WebKit

struct HTMLStringView: NSViewRepresentable {
    var htmlContent: String
    
    // Initialize and configure the WKWebView with initial hidden state
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.alphaValue = 0.0  // Start with the webView fully transparent
        return webView
    }
    
    // Load HTML content with embedded CSS to initially hide the body
    func updateNSView(_ nsView: WKWebView, context: Context) {
        let modifiedHtmlContent = """
        <style>
        body { visibility: hidden; font-family: Optima, Bookerly, 'Source Han Serif CN'; } // Ensure body is hidden until fully styled
        </style>
        \(htmlContent)
        """
        nsView.loadHTMLString(modifiedHtmlContent, baseURL: nil)
    }
    
    // Coordinator to handle web navigation events
    class Coordinator: NSObject, WKNavigationDelegate {
        // Adjust web content and visibility after the page has loaded
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // JavaScript to adjust the scale and reveal the body
            let script = "document.documentElement.style.zoom = '0.8'; document.body.style.visibility = 'visible';"
            webView.evaluateJavaScript(script) { _, _ in
                DispatchQueue.main.async {
                    // Transition the webView to full opacity once adjustments are complete
                    NSAnimationContext.runAnimationGroup({ context in
                        context.duration = 0.25
                        webView.animator().alphaValue = 1.0
                    })
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}

struct CustomWebView: View {
    @Binding var htmlString: String
    
    var body: some View {
        let paragraphs = htmlString.components(separatedBy: "\n").map { "<p>\($0)</p>" }.joined()
        
        HTMLStringView(htmlContent: paragraphs)
            .lineSpacing(2)
            .padding([.top, .bottom], -5)
            .padding([.leading, .trailing], 0)
            .background(Color.white)
            .cornerRadius(5)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.gray, lineWidth: 1)
            )
    }
}
