//
//  ServerStatusView.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/7/6.
//

import SwiftUI
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
