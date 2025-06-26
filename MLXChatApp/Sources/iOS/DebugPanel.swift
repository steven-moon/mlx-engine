// DebugPanel.swift
// MLXChatApp
//
// Developer debug panel for inspecting logs and generating debug reports.
// Only included in DEBUG builds.

#if DEBUG
import SwiftUI
import MLXEngine

struct DebugPanel: View {
    @State private var selectedLevels: Set<LogLevel> = [.error, .warning, .critical]
    @State private var recentLogs: [LogEntry] = []
    @State private var debugReport: String = ""
    @State private var isReportCopied = false
    @State private var isLoadingReport = false
    @State private var logLimit: Double = 50

    private let allLevels: [LogLevel] = [.debug, .info, .warning, .error, .critical]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Debug Panel")
                .font(.title2)
                .bold()

            // Log level filter
            HStack {
                Text("Log Levels:")
                ForEach(allLevels, id: \.self) { level in
                    Button(action: {
                        if selectedLevels.contains(level) {
                            selectedLevels.remove(level)
                        } else {
                            selectedLevels.insert(level)
                        }
                        loadLogs()
                    }) {
                        Text(level.rawValue.capitalized)
                            .padding(6)
                            .background(selectedLevels.contains(level) ? Color.blue.opacity(0.7) : Color.gray.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }

            // Log limit slider
            HStack {
                Text("Show last ")
                Slider(value: $logLimit, in: 10...200, step: 10, onEditingChanged: { _ in loadLogs() })
                    .frame(width: 120)
                Text("\(Int(logLimit)) logs")
            }

            // Logs list
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    if recentLogs.isEmpty {
                        Text("No logs for selected levels.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(recentLogs) { entry in
                            HStack(alignment: .top, spacing: 8) {
                                Text(entry.level.emoji)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("[\(entry.level.rawValue.uppercased())] [\(entry.tag)] ")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(entry.message)
                                        .font(.body)
                                    if let context = entry.context, !context.isEmpty {
                                        Text(context.map { "\($0): \($1)" }.joined(separator: ", "))
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                    Text(entry.source)
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Text(entry.timestamp, style: .time)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            .padding(6)
                            .background(
                                {
                                    #if os(iOS) || os(tvOS) || os(visionOS)
                                    return Color(UIColor.secondarySystemBackground)
                                    #elseif os(macOS)
                                    return Color(NSColor.windowBackgroundColor)
                                    #else
                                    return Color.gray.opacity(0.15)
                                    #endif
                                }()
                            )
                            .cornerRadius(6)
                        }
                    }
                }
            }
            .frame(maxHeight: 300)
            .onAppear(perform: loadLogs)

            // Debug report
            HStack {
                Button(action: generateReport) {
                    if isLoadingReport {
                        ProgressView()
                    } else {
                        Text("Generate Debug Report")
                    }
                }
                .disabled(isLoadingReport)
                if !debugReport.isEmpty {
                    Button(action: copyReport) {
                        Text(isReportCopied ? "Copied!" : "Copy Report")
                    }
                }
            }
            if !debugReport.isEmpty {
                ScrollView {
                    Text(debugReport)
                        .font(.system(.footnote, design: .monospaced))
                        .padding(4)
                        .background(
                            {
                                #if os(iOS) || os(tvOS) || os(visionOS)
                                return Color(UIColor.systemGray6)
                                #elseif os(macOS)
                                return Color(NSColor.windowBackgroundColor)
                                #else
                                return Color.gray.opacity(0.15)
                                #endif
                            }()
                        )
                        .cornerRadius(6)
                }
                .frame(maxHeight: 200)
            }
        }
        .padding()
        .background(
            {
                #if os(iOS) || os(tvOS) || os(visionOS)
                return Color(UIColor.systemBackground)
                #elseif os(macOS)
                return Color(NSColor.windowBackgroundColor)
                #else
                return Color.gray.opacity(0.15)
                #endif
            }()
        )
        .cornerRadius(12)
        .shadow(radius: 8)
        .onAppear(perform: loadLogs)
    }

    private func loadLogs() {
        let levels = selectedLevels.isEmpty ? nil : Array(selectedLevels)
        recentLogs = AppLogger.shared.recentLogs(limit: Int(logLimit), levels: levels)
    }

    private func generateReport() {
        isLoadingReport = true
        Task {
            let report = await DebugUtility.shared.generateDebugReport(onlyErrorsAndWarnings: selectedLevels.isSuperset(of: [.error, .warning, .critical]) && selectedLevels.count <= 3)
            await MainActor.run {
                debugReport = report
                isLoadingReport = false
                isReportCopied = false
            }
        }
    }

    private func copyReport() {
        #if os(iOS)
        UIPasteboard.general.string = debugReport
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(debugReport, forType: .string)
        #endif
        isReportCopied = true
    }
}

private extension LogLevel {
    var emoji: String {
        switch self {
        case .debug: return "🟦"
        case .info: return "🟩"
        case .warning: return "🟨"
        case .error: return "🟥"
        case .critical: return "🔥"
        }
    }
}

#endif 