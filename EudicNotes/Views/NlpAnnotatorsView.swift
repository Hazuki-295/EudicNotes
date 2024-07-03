//
//  NlpAnnotatorsView.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/6/11.
//

import SwiftUI
import WebKit
import Combine

struct ServerStatusView: View {
    @ObservedObject var viewModel: ServerStatusViewModel
    
    var body: some View {
        Circle()
            .fill(viewModel.isServerAvailable ? Color.green : Color.red)
            .frame(width: 5, height: 5)
            .overlay(
                Circle()
                    .stroke(Color.gray, lineWidth: 0.4)
            )
            .onAppear {
                viewModel.startCheckingServer()
            }
    }
}

class ServerStatusViewModel: ObservableObject {
    @Published var isServerAvailable: Bool = false
    private var timer: AnyCancellable?
    
    func startCheckingServer() {
        self.checkServerStatus() // Initial check
        
        timer = Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                self.checkServerStatus()
            }
    }
    
    private func checkServerStatus() {
        guard let url = URL(string: "http://127.0.0.1:8000/status") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5.0
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    self.isServerAvailable = true
                } else {
                    self.isServerAvailable = false
                }
            }
        }.resume()
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

func loadResourceContent(fileName: String, withExtension: String) -> String? {
    if let url = Bundle.main.url(forResource: fileName, withExtension: withExtension),
       let content = try? String(contentsOf: url) {
        return content
    }
    return nil
}

struct WebView: NSViewRepresentable {
    var htmlContent: String
    var initialJsToExecute: String?
    
    @Binding var webView: WKWebView?
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Execute initial JavaScript once the web view finishes loading
            if let jsToExecute = parent.initialJsToExecute {
                webView.evaluateJavaScript(jsToExecute) { result, error in
                    if let error = error {
                        print("Initial JavaScript execution error: \(error.localizedDescription)")
                    } else {
                        print("Initial JavaScript execution result: \(result ?? "No result")")
                    }
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        DispatchQueue.main.async {
            self.webView = webView
        }
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        nsView.loadHTMLString(htmlContent, baseURL: URL(string: "http://127.0.0.1:8000"))
    }
    
    func executeJavaScript(_ jsToExecute: String) {
        webView?.evaluateJavaScript(jsToExecute) { result, error in
            if let error = error {
                print("JavaScript execution error: \(error.localizedDescription)")
            } else {
                print("JavaScript execution result: \(result ?? "No result")")
            }
        }
    }
}

// Custom WebView for NLP display with consistent styling
struct NLPView: View {
    var htmlContent: String
    var initialJsToExecute: String?
    @Binding var webView: WKWebView?
    
    var body: some View {
        WebView(htmlContent: htmlContent, initialJsToExecute: initialJsToExecute, webView: $webView)
            .lineSpacing(2)
            .background(Color.white)
            .cornerRadius(5)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.gray, lineWidth: 1)
            )
    }
}

// Main view managing NLP annotations
struct NlpAnnotatorsView: View {
    static private var defaultInput = "The quick brown fox jumped over the lazy dog."
    @State private var input: String = defaultInput
    
    @State private var spacyHTML: String = ""
    @State private var spacyWebView: WKWebView? = nil
    
    @State private var corenlpHTML: String = ""
    @State private var corenlpWebView: WKWebView? = nil
    
    @State private var serverAvailableActionPerformed: Bool = false
    @StateObject private var serverStatusViewModel = ServerStatusViewModel()
    
    @State private var selectAnnotators = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Label("Text to annotate:", systemImage: "book")
                TextField("Enter input", text: $input)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        submitData()
                    }
                Button(action: { submitData() }) {
                    HStack {
                        Image(systemName: "paperplane")
                        Text("Submit")
                        ServerStatusView(viewModel: serverStatusViewModel)
                    }
                }
            }
            
            VStack(alignment: .leading) {
                HStack {
                    Label("Stanford CoreNLP", systemImage: "note.text").foregroundColor(Color(hexString: "#aa1d36"))
                    Spacer()
                    Toggle("Custom Annotators", isOn: $selectAnnotators).onChange(of: selectAnnotators) {
                        corenlpWebView?.evaluateJavaScript("toggleAnnotatorSelector();")
                    }
                    Image("corenlp").resizable().scaledToFit().background().border(Color.gray)
                }
                .frame(height: 30)
                NLPView(htmlContent: corenlpHTML, initialJsToExecute: "initCorenlp('\(NlpAnnotatorsView.defaultInput)')", webView: $corenlpWebView)
            }
            
            VStack(alignment: .leading) {
                HStack {
                    Label("spaCy Dependency", systemImage: "note.text.badge.plus").foregroundColor(Color(hexString: "#0072cf"))
                    Spacer()
                    Image("spacy").resizable().scaledToFit()
                }
                .frame(height: 30)
                NLPView(htmlContent: spacyHTML, webView: $spacyWebView)
            }
        }
        .padding(.top, 5)
        .padding(.bottom)
        .padding(.leading)
        .padding(.trailing)
        .onReceive(serverStatusViewModel.$isServerAvailable) { isServerAvailable in
            if isServerAvailable && !serverAvailableActionPerformed {
                initCoreNLP();
                submitSpacyData();
                serverAvailableActionPerformed = true
            }
        }
    }
    
    func initCoreNLP() {
        var request = URLRequest(url: URL(string: "http://127.0.0.1:8000/CoreNLP")!)
        request.httpMethod = "GET"
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data, let htmlContent = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    corenlpHTML = htmlContent
                }
            } else {
                print("Failed to fetch data: \(error?.localizedDescription ?? "Unknown error")")
            }
        }.resume()
    }
    
    func submitData() {
        submitSpacyData();
        submitCorenlpData();
    }
    
    func submitSpacyData () {
        var request = URLRequest(url: URL(string: "http://127.0.0.1:8000/spaCy")!)
        request.httpMethod = "POST"
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.httpBody = input.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data, let htmlContent = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    spacyHTML = htmlContent
                }
            } else {
                print("Failed to fetch data: \(error?.localizedDescription ?? "Unknown error")")
            }
        }.resume()
    }
    
    func submitCorenlpData() {
        corenlpWebView?.evaluateJavaScript("setInputAndSubmit('\(input)');")
    }
}

#Preview {
    OptionsView()
}
