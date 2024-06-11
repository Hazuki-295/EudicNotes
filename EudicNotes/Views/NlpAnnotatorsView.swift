//
//  NlpAnnotatorsView.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/6/11.
//

import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
    var htmlContent: String
    
    func makeNSView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        nsView.loadHTMLString(htmlContent, baseURL: nil)
    }
}

// Custom WebView for NLP display with consistent styling
struct NLPView: View {
    var htmlContent: String
    
    var body: some View {
        WebView(htmlContent: htmlContent)
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
    @State private var input: String = "The big zucchini in the freezer will be shredded for bread."
    @State private var spacyHTML: String = ""
    @State private var corenlpHTML: String = ""
    @State private var hasAppeared: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Label("Text to annotate:", systemImage: "square.and.pencil")
                TextField("Enter input", text: $input)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        submitData()
                    }
                Button(action: { submitData() }) {
                    HStack {
                        Image(systemName: "paperplane")
                        Text("Submit")
                    }
                }
            }
            
            NLPView(htmlContent: corenlpHTML)
            NLPView(htmlContent: spacyHTML)
        }
        .padding(.top, 5)
        .padding(.bottom)
        .padding(.leading)
        .padding(.trailing)
        .onAppear {
            if !hasAppeared {
                submitData(); hasAppeared = true
            }
        }
    }
    
    func submitData() {
        fetchData(for: "CoreNLP", htmlString: $corenlpHTML)
        fetchData(for: "spaCy", htmlString: $spacyHTML)
    }
    
    func fetchData(for endpoint: String, htmlString: Binding<String>) {
        guard let url = URL(string: "http://127.0.0.1:5000/\(endpoint)") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.httpBody = input.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, let htmlContent = String(data: data, encoding: .utf8) else {
                print("Failed to fetch data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            DispatchQueue.main.async {
                htmlString.wrappedValue = htmlContent
            }
        }.resume()
    }
}

#Preview {
    OptionsView()
}
