//
//  NlpAnnotatorsView.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/6/11.
//

import SwiftUI
import WebKit

// Custom WebView for NLP display with consistent styling
struct NLPView: View {
    @Binding var htmlContent: String
    var webView: WKWebView
    var initialJsToExecute: String?
    
    var body: some View {
        WebView(htmlContent: $htmlContent, webView: webView, initialJsToExecute: initialJsToExecute)
            .lineSpacing(2)
            .background(Color.white)
            .cornerRadius(5)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.gray, lineWidth: 1)
            )
    }
    
    func executeJavaScript(js: String, completion: ((Result<Any?, Error>) -> Void)? = nil) {
        webView.evaluateJavaScript(js) { result, error in
            if let error = error {
                completion?(.failure(error))
            } else {
                completion?(.success(result))
            }
        }
    }
}

// Main view managing NLP annotations
struct NlpAnnotatorsView: View {
    static private var defaultInput = "The quick brown fox jumped over the lazy dog."
    @State private var input: String = defaultInput
    
    @State private var spacyHTML: String = ""
    @State private var spacyNLPView: NLPView!
    
    @State private var corenlpHTML: String = ""
    @State private var corenlpNLPView: NLPView!
    @State private var selectAnnotators = false
    
    @State private var serverAvailableActionPerformed: Bool = false
    @StateObject private var serverStatusViewModel = ServerStatusViewModel()
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Label("Text to annotate:", systemImage: "book")
                TextField("Enter input", text: $input)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit { submitData() }
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
                    Label("Stanford CoreNLP", systemImage: "note.text").foregroundColor(.corenlp)
                    Spacer()
                    Toggle("Custom Annotators", isOn: $selectAnnotators).onChange(of: selectAnnotators) {
                        corenlpNLPView.executeJavaScript(js: "toggleAnnotatorSelector();")
                    }
                    Image("corenlp").resizable().scaledToFit().background().border(Color.gray)
                }
                .frame(height: 30)
                
                NLPView(htmlContent: $corenlpHTML, webView: WKWebView(), initialJsToExecute: "initCorenlp('\(NlpAnnotatorsView.defaultInput)')")
            }
            
            VStack(alignment: .leading) {
                HStack {
                    Label("spaCy Dependency", systemImage: "note.text.badge.plus").foregroundColor(.oaldBlue)
                    Spacer()
                    Image("spacy").resizable().scaledToFit()
                }
                .frame(height: 30)
                
                NLPView(htmlContent: $spacyHTML, webView: WKWebView())
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
        corenlpNLPView.executeJavaScript(js: "setInputAndSubmit('\(input)');")
    }
}

#Preview {
    OptionsView()
}
