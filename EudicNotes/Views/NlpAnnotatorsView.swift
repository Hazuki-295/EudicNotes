//
//  NlpAnnotatorsView.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/6/11.
//

import SwiftUI
import WebKit
import Combine

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

struct ServerStatusView: View {
    @StateObject private var viewModel = ServerStatusViewModel()
    
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

// Main view managing NLP annotations
struct NlpAnnotatorsView: View {
    @State private var input: String = "The big zucchini in the freezer will be shredded for bread."
    @State private var spacyHTML: String = ""
    @State private var corenlpHTML: String = ""
    @State private var hasAppeared: Bool = false
    
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
                        ServerStatusView()
                    }
                }
            }
            
            VStack(alignment: .leading) {
                HStack {
                    Label("Stanford CoreNLP", systemImage: "note.text").foregroundColor(Color(hexString: "#aa1d36"))
                    Spacer()
                    Image("corenlp").resizable().scaledToFit().background().border(Color.gray)
                }
                .frame(height: 30)
                NLPView(htmlContent: corenlpHTML)
            }
            
            VStack(alignment: .leading) {
                HStack {
                    Label("spaCy Dependency", systemImage: "note.text.badge.plus").foregroundColor(Color(hexString: "#0072cf"))
                    Spacer()
                    Image("spacy").resizable().scaledToFit()
                }
                .frame(height: 30)
                NLPView(htmlContent: spacyHTML)
            }
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
        guard let url = URL(string: "http://127.0.0.1:8000/\(endpoint)") else {
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
