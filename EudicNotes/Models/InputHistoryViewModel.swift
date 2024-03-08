//
//  InputHistoryViewModel.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/3/7.
//

import Foundation

class InputHistoryViewModel: ObservableObject {
    @Published var history: [String] = []
    let historyEntryLimit: Int = 15
    
    private let key: String
    
    init(variableName: String) {
        self.key = variableName
        loadHistory()
    }
    
    func loadHistory() {
        history = UserDefaults.standard.stringArray(forKey: key) ?? []
    }
    
    func saveHistory() {
        UserDefaults.standard.set(history, forKey: key)
    }
    
    func addToHistory(newEntry: String) {
        guard !newEntry.isEmpty, !history.contains(newEntry) else { return }
        history.append(newEntry)
        history.sort()
        if history.count > historyEntryLimit {
            history = Array(history.prefix(historyEntryLimit))
        }
        saveHistory()
    }
}
