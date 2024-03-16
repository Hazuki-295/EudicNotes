//
//  InputHistoryViewModel.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/3/7.
//

import Foundation

/// Manages a history of input strings with a limit on the number of entries.
class InputHistoryViewModel: ObservableObject {
    @Published var history: [String] = []
    private let historyEntryLimit: Int = 30
    private let key: String
    
    /// Initializes a new `InputHistoryViewModel` with a specific UserDefaults key.
    /// - Parameter variableName: The key used for storing the history in UserDefaults.
    init(variableName: String) {
        self.key = variableName
        loadHistory()
    }
    
    /// Loads the history from UserDefaults.
    private func loadHistory() {
        history = UserDefaults.standard.stringArray(forKey: key) ?? []
    }
    
    /// Saves the current history to UserDefaults.
    private func saveHistory() {
        UserDefaults.standard.set(history, forKey: key)
    }
    
    /// Adds a new entry to the history, ensuring no duplicates and respecting the entry limit.
    /// - Parameter newEntry: The new string to add to the history.
    func addToHistory(newEntry: String) {
        guard !newEntry.isEmpty, !history.contains(newEntry) else { return }
        
        // Add the new entry
        history.append(newEntry)
        
        // Ensure the history does not exceed the limit
        if history.count > historyEntryLimit {
            history.removeFirst() // Remove the oldest entry
        }
        
        saveHistory()
    }
}
