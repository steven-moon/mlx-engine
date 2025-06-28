import Foundation
import Logging
import MLXEngine

#if DEBUG || CLI
  import ArgumentParser

  @main
  struct DebugReportCLI: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
      commandName: "mlxengine-debug-report",
      abstract: "MLXEngine developer CLI tools.",
      subcommands: [
        Debug.self, ListModels.self, CleanupCache.self, DownloadModel.self, ShowModelInfo.self,
        ListRemoteModels.self, ExportLog.self,
      ],
      defaultSubcommand: Debug.self
    )

    struct Debug: AsyncParsableCommand {
      static var configuration = CommandConfiguration(
        abstract: "Prints a debug report, including recent logs and system info.")
      @Flag(name: .shortAndLong, help: "Only include error and warning logs.")
      var errorsOnly: Bool = false
      func run() async throws {
        let report = await DebugUtility.shared.generateDebugReport(
          onlyErrorsAndWarnings: errorsOnly)
        print(report)
      }
    }

    struct ListModels: AsyncParsableCommand {
      static var configuration = CommandConfiguration(abstract: "Lists all downloaded models.")
      func run() async throws {
        do {
          let downloader = ModelDownloader()
          let models = try await downloader.getDownloadedModels()
          if models.isEmpty {
            print("No downloaded models found.")
          } else {
            print("Downloaded Models:")
            for model in models {
              print("- \(model.name) (hubId: \(model.hubId))")
            }
          }
        } catch {
          print("Error listing models: \(error)")
        }
      }
    }

    struct CleanupCache: AsyncParsableCommand {
      static var configuration = CommandConfiguration(abstract: "Cleans up temporary/cache files.")
      func run() async throws {
        do {
          try FileManagerService.shared.cleanupTemporaryFiles()
          print("Temporary/cache files cleaned up successfully.")
        } catch {
          print("Error cleaning up cache: \(error)")
        }
      }
    }

    struct DownloadModel: AsyncParsableCommand {
      static var configuration = CommandConfiguration(
        abstract: "Downloads a model from the remote hub.")
      @Argument(help: "The model hubId to download.")
      var hubId: String
      func run() async throws {
        let downloader = ModelDownloader()
        let modelConfig = ModelConfiguration(
          name: hubId,
          hubId: hubId,
          description: "Downloaded via CLI"
        )
        print("Downloading model: \(hubId)")
        // Use an actor to safely track progress
        actor ProgressTracker {
          var lastPercent: Int = -1
          func setLastPercent(_ value: Int) {
            lastPercent = value
          }
        }
        let tracker = ProgressTracker()
        let _ = try await downloader.downloadModel(modelConfig) { progress in
          Task { @MainActor in
            let percent = Int(progress * 100)
            let last = await tracker.lastPercent
            if percent != last {
              print("Download progress: \(percent)%")
              await tracker.setLastPercent(percent)
            }
          }
        }
        print("Download complete.")
      }
    }

    struct ShowModelInfo: AsyncParsableCommand {
      static var configuration = CommandConfiguration(
        abstract: "Shows detailed info for a model by modelId.")
      @Argument(help: "The modelId to show info for (e.g., mlx-community/Qwen1.5-0.5B-Chat-4bit)")
      var modelId: String
      func run() async throws {
        let downloader = ModelDownloader()
        var config: ModelConfiguration?
        if let regConfig = ModelRegistry.findModel(by: modelId) {
          config = regConfig
        } else {
          let found = try await downloader.searchModels(query: modelId, limit: 1)
          if let first = found.first { config = first }
        }
        guard let model = config else {
          print("Could not find model info for: \(modelId)")
          return
        }
        print("Model Info:")
        print("  Name: \(model.name)")
        print("  Hub ID: \(model.hubId)")
        print("  Description: \(model.description)")
        if let params = model.parameters { print("  Parameters: \(params)") }
        if let quant = model.quantization { print("  Quantization: \(quant)") }
        if let arch = model.architecture { print("  Architecture: \(arch)") }
        print("  Max Tokens: \(model.maxTokens)")
        if let size = model.estimatedSizeGB { print("  Estimated Size (GB): \(size)") }
        if let prompt = model.defaultSystemPrompt { print("  Default System Prompt: \(prompt)") }
        if let tokens = model.endOfTextTokens {
          print("  End-of-Text Tokens: \(tokens.joined(separator: ", "))")
        }
        if let engine = model.engineType { print("  Engine Type: \(engine)") }
        if let url = model.downloadURL { print("  Download URL: \(url)") }
        if let isDownloaded = model.isDownloaded { print("  Downloaded: \(isDownloaded)") }
        if let localPath = model.localPath { print("  Local Path: \(localPath)") }
      }
    }

    struct ListRemoteModels: AsyncParsableCommand {
      static var configuration = CommandConfiguration(
        abstract: "Lists MLX-compatible models from Hugging Face by query.")
      @Argument(help: "Query string to search for (e.g., Qwen, Llama, mlx)")
      var query: String
      func run() async throws {
        let results = try await ModelDiscoveryService.searchMLXModels(query: query, limit: 20)
        if results.isEmpty {
          print("No MLX-compatible models found for query: \(query)")
          return
        }
        print("MLX-compatible models for query: \(query)")
        for model in results {
          print(
            "- \(model.name) (hubId: \(model.id)), downloads: \(model.downloads), likes: \(model.likes), quant: \(model.quantization ?? "n/a"), params: \(model.parameters ?? "n/a"), arch: \(model.architecture ?? "n/a")"
          )
        }
      }
    }

    struct ExportLog: AsyncParsableCommand {
      static var configuration = CommandConfiguration(
        abstract: "Exports the persistent log file or prints the last N lines.")
      @Option(name: .shortAndLong, help: "Number of lines to print from the end of the log file.")
      var lines: Int = 100
      func run() async throws {
        guard let url = AppLogger.shared.getLogFileURL(),
          FileManager.default.fileExists(atPath: url.path)
        else {
          print("No persistent log file found.")
          return
        }
        print("Log file path: \(url.path)")
        let data = try Data(contentsOf: url)
        guard let text = String(data: data, encoding: .utf8) else {
          print("Could not decode log file.")
          return
        }
        let allLines = text.split(separator: "\n", omittingEmptySubsequences: false)
        let tail = allLines.suffix(lines)
        print("--- Last \(lines) lines of log file ---")
        for line in tail { print(line) }
      }
    }
  }
#endif
