//
//  Logger.swift
//  EudicNotes
//
//  Created by 叶月 on 2024/7/8.
//

import Foundation
import os.log

class Logger {
    private let subsystem: String
    private let log: OSLog
    
    enum Level: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
    }
    
    init(subsystem: String, category: String = "Application") {
        self.subsystem = subsystem
        self.log = OSLog(subsystem: subsystem, category: category)
    }
    
    func debug(_ message: String) {
        log(message, level: .debug)
    }
    
    func info(_ message: String) {
        log(message, level: .info)
    }
    
    func warning(_ message: String) {
        log(message, level: .warning)
    }
    
    func error(_ message: String) {
        log(message, level: .error)
    }
    
    private func log(_ message: String, level: Level) {
        os_log("%@", log: self.log, type: OSLogType(level: level), message)
    }
    
    private func OSLogType(level: Level) -> OSLogType {
        switch level {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        }
    }
}
