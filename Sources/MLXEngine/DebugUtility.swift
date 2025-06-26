//
//  DebugUtility.swift
//  MLXEngine
//
//  Created by OpenAI on 2024-08-01.
//

import Foundation
import os.log
#if os(iOS)
import UIKit
#endif

// MARK: - LogLevel
public enum LogLevel: String, Codable {
    case debug, info, warning, error, critical
}

// MARK: - LogEntry
public struct LogEntry: Codable, Identifiable {
    public var id: UUID { UUID(uuidString: "\(timestamp.timeIntervalSince1970)-\(level.rawValue)-\(tag)-\(message)".hashValue.description) ?? UUID() }
    public let timestamp: Date
    public let level: LogLevel
    public let tag: String
    public let message: String
    public let source: String // file:function:line
    public let context: [String: String]?
}

// MARK: - LogSink Protocol
public protocol LogSink: Sendable {
    func log(_ entry: LogEntry)
}

// MARK: - ConsoleLogSink
public struct ConsoleLogSink: LogSink {
    public func log(_ entry: LogEntry) {
        let dateStr = ISO8601DateFormatter().string(from: entry.timestamp)
        let levelEmoji: String
        switch entry.level {
        case .debug: levelEmoji = "🟦"
        case .info: levelEmoji = "🟩"
        case .warning: levelEmoji = "🟨"
        case .error: levelEmoji = "🟥"
        case .critical: levelEmoji = "🔥"
        }
        let contextStr = entry.context?.map { "\($0): \($1)" }.joined(separator: ", ") ?? ""
        print("\(dateStr) \(levelEmoji) [\(entry.tag)] \(entry.message) \(contextStr) (\(entry.source))")
    }
}

// MARK: - FileLogSink
public struct FileLogSink: LogSink {
    public let logFileURL: URL
    
    public func log(_ entry: LogEntry) {
        let dateStr = ISO8601DateFormatter().string(from: entry.timestamp)
        let levelEmoji: String
        switch entry.level {
        case .debug: levelEmoji = "🟦"
        case .info: levelEmoji = "🟩"
        case .warning: levelEmoji = "🟨"
        case .error: levelEmoji = "🟥"
        case .critical: levelEmoji = "🔥"
        }
        let contextStr = entry.context?.map { "\($0): \($1)" }.joined(separator: ", ") ?? ""
        let logEntry = "\(dateStr) \(levelEmoji) [\(entry.tag)] \(entry.message) \(contextStr) (\(entry.source))\n"
        // Synchronously append or create
        if let data = logEntry.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                if let handle = try? FileHandle(forWritingTo: logFileURL) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    try? handle.close()
                }
            } else {
                try? data.write(to: logFileURL, options: .atomic)
            }
        }
    }
}

/// Thread-safe, global logger for MLXEngine
public final class AppLogger {
    public static let shared = AppLogger()
    private var sinks: [LogSink] = [ConsoleLogSink()]
    private let queue = DispatchQueue(label: "AppLoggerQueue", qos: .utility)
    private var logBuffer: [LogEntry] = []
    private let maxLogBufferSize = 200
    private let maxLogFileSize: UInt64 = 5 * 1024 * 1024 // 5MB
    private var logFileURL: URL? = nil
    
    private init() {
        // Set up persistent file log sink
        do {
            let cacheDir = try FileManagerService.shared.getCacheDirectory()
            let logFile = cacheDir.appendingPathComponent("mlxengine.log")
            logFileURL = logFile
            // Rotate/truncate if too large
            if FileManager.default.fileExists(atPath: logFile.path) {
                let attrs = try FileManager.default.attributesOfItem(atPath: logFile.path)
                if let size = attrs[.size] as? UInt64, size > maxLogFileSize {
                    try? FileManager.default.removeItem(at: logFile)
                }
            }
            sinks.append(FileLogSink(logFileURL: logFile))
            // Emit a log event to ensure file is created
            let entry = LogEntry(timestamp: Date(), level: .info, tag: "AppLogger", message: "Logger initialized", source: "AppLogger.init", context: nil)
            for sink in sinks { sink.log(entry) }
        } catch {
            // Ignore file sink errors, fallback to in-memory/console only
        }
    }

    public func addSink(_ sink: LogSink) {
        queue.sync { sinks.append(sink) }
    }
    public func removeAllSinks() {
        queue.sync { sinks.removeAll() }
    }

    public func log(_ level: LogLevel, tag: String, message: String, context: [String: String]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let source = "\(URL(fileURLWithPath: file).lastPathComponent):\(function):\(line)"
        let entry = LogEntry(timestamp: Date(), level: level, tag: tag, message: message, source: source, context: context)
        queue.async {
            self.logBuffer.append(entry)
            if self.logBuffer.count > self.maxLogBufferSize {
                self.logBuffer.removeFirst(self.logBuffer.count - self.maxLogBufferSize)
            }
            for sink in self.sinks { sink.log(entry) }
        }
    }

    // Returns a snapshot of the most recent log entries, optionally filtered by level
    public func recentLogs(limit: Int = 50, levels: [LogLevel]? = nil) -> [LogEntry] {
        queue.sync {
            let filtered = levels == nil ? logBuffer : logBuffer.filter { levels!.contains($0.level) }
            let count = min(limit, filtered.count)
            return Array(filtered.suffix(count))
        }
    }

    // Convenience methods
    public func debug(_ tag: String, _ message: String, context: [String: String]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(.debug, tag: tag, message: message, context: context, file: file, function: function, line: line)
    }
    public func info(_ tag: String, _ message: String, context: [String: String]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(.info, tag: tag, message: message, context: context, file: file, function: function, line: line)
    }
    public func warning(_ tag: String, _ message: String, context: [String: String]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(.warning, tag: tag, message: message, context: context, file: file, function: function, line: line)
    }
    public func error(_ tag: String, _ message: String, context: [String: String]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(.error, tag: tag, message: message, context: context, file: file, function: function, line: line)
    }
    public func critical(_ tag: String, _ message: String, context: [String: String]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(.critical, tag: tag, message: message, context: context, file: file, function: function, line: line)
    }

    /// Returns the current log file URL, if available
    public func getLogFileURL() -> URL? {
        logFileURL
    }
}

// MARK: - Example Usage (remove in production)
#if DEBUG
public func exampleLoggerUsage() {
    AppLogger.shared.info("Test", "Logger initialized", context: ["user": "stevenmoon"])
    AppLogger.shared.error("Inference", "Failed to load model", context: ["modelId": "mlx-community/Qwen1.5-0.5B-Chat-4bit"])
}
#endif

// MARK: - Tiny lock-free atomics for primitives
fileprivate final class AtomicBool {
    private var value: UInt32 = 0
    @inline(__always) func load() -> Bool { value == 1 }
    @inline(__always) func store(_ new: Bool) { value = new ? 1 : 0 }
}

fileprivate final class AtomicInt {
    private var value: Int32 = 0
    @inline(__always) func load() -> Int { Int(OSAtomicAdd32Barrier(0, &value)) }
    @inline(__always) func store(_ new: Int) { OSAtomicCompareAndSwap32Barrier(value, Int32(new), &value) }
}

/// Utility for generating debug reports and system info for MLXEngine
public actor DebugUtility {
    public static let shared = DebugUtility()
    
    /// The most recent debug report (cached)
    public private(set) var lastReport: String = ""
    
    /// Generates a comprehensive debug report for diagnostics
    /// - Parameter onlyErrorsAndWarnings: If true, only include error and warning logs
    public func generateDebugReport(models: [String]? = nil, onlyErrorsAndWarnings: Bool = false) async -> String {
        var report = "=== MLXEngine Debug Report ===\n"
        report += "App Version: \(Self.appVersion)\n"
        report += "OS Version: \(ProcessInfo.processInfo.operatingSystemVersionString)\n"
        report += "Device: \(Self.deviceName)\n"
        report += "Date: \(Date())\n\n"
        report += await generateSystemInfo()
        report += await generateModelInfo(models: models)
        report += generateLoggerConfig()
        let levels: [LogLevel]? = onlyErrorsAndWarnings ? [.error, .critical, .warning] : nil
        report += generateRecentLogs(levels: levels)
        report += "--- End Debug Report ---\n"
        lastReport = report
        return report
    }
    
    /// Generates system information (memory, CPU, disk)
    private func generateSystemInfo() async -> String {
        var info = "--- SYSTEM INFO ---\n"
        let memory = ProcessInfo.processInfo.physicalMemory
        let memoryGB = Double(memory) / (1024 * 1024 * 1024)
        info += String(format: "Physical Memory: %.1f GB\n", memoryGB)
        info += "CPU Count: \(ProcessInfo.processInfo.processorCount)\n"
        info += "Active CPUs: \(ProcessInfo.processInfo.activeProcessorCount)\n"
        if let disk = await getDiskInfo() {
            info += String(format: "Disk: %.1f GB free / %.1f GB total\n", disk.available, disk.total)
        }
        info += "\n"
        return info
    }
    
    /// Generates model information (stub, can be extended)
    private func generateModelInfo(models: [String]? = nil) async -> String {
        var info = "--- MODEL INFO ---\n"
        if let models = models, !models.isEmpty {
            info += "Models: \(models.joined(separator: ", "))\n"
        } else {
            info += "No model info provided.\n"
        }
        info += "\n"
        return info
    }
    
    /// Returns logger configuration
    private func generateLoggerConfig() -> String {
        var config = "--- LOGGER CONFIG ---\n"
        config += "All logs enabled (no minimum level set)\n\n"
        return config
    }
    
    /// Returns recent logs (in-memory buffer), optionally filtered by level
    private func generateRecentLogs(levels: [LogLevel]? = nil) -> String {
        var logs = "--- RECENT LOGS ---\n"
        let entries = AppLogger.shared.recentLogs(limit: 50, levels: levels)
        if entries.isEmpty {
            logs += "(No recent logs)\n\n"
        } else {
            let formatter = ISO8601DateFormatter()
            for entry in entries {
                let dateStr = formatter.string(from: entry.timestamp)
                let contextStr = entry.context?.map { "\($0): \($1)" }.joined(separator: ", ") ?? ""
                logs += "\(dateStr) [\(entry.level.rawValue.uppercased())] [\(entry.tag)] \(entry.message) \(contextStr) (\(entry.source))\n"
            }
            logs += "\n"
        }
        return logs
    }
    
    /// Gets disk info (free/total GB)
    private func getDiskInfo() async -> (available: Double, total: Double)? {
        let fileManager = FileManager.default
        guard let path = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        do {
            let attrs = try fileManager.attributesOfFileSystem(forPath: path.path)
            let free = attrs[.systemFreeSize] as? NSNumber
            let total = attrs[.systemSize] as? NSNumber
            if let free = free?.doubleValue, let total = total?.doubleValue {
                return (free / (1024 * 1024 * 1024), total / (1024 * 1024 * 1024))
            }
        } catch {}
        return nil
    }
    
    /// Returns the app version string
    private static var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "\(version) (\(build))"
        }
        return "Unknown"
    }
    
    /// Returns the device name (cross-platform)
    private static var deviceName: String {
        #if os(macOS)
        return ProcessInfo.processInfo.hostName
        #elseif os(iOS)
        return UIDevice.current.name
        #else
        return "Unknown Device"
        #endif
    }
} 