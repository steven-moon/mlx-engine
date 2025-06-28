import XCTest

@testable import MLXEngine

final class ModelManagerTests: XCTestCase {
  var fileManagerService: FileManagerService!

  override func setUp() {
    super.setUp()
    fileManagerService = FileManagerService.shared
  }

  override func tearDown() {
    fileManagerService = nil
    super.tearDown()
  }

  func testGetModelsDirectory() throws {
    let directory = try fileManagerService.getModelsDirectory()
    XCTAssertTrue(directory.hasDirectoryPath)
  }

  func testModelsDirectoryExists() throws {
    let modelsDirectory = try fileManagerService.getModelsDirectory()
    XCTAssertTrue(FileManager.default.fileExists(atPath: modelsDirectory.path))
  }

  func testDeleteModel() throws {
    let modelsDirectory = try fileManagerService.getModelsDirectory()
    let testModelDirectory = modelsDirectory.appendingPathComponent("test-model")
    try FileManager.default.createDirectory(
      at: testModelDirectory, withIntermediateDirectories: true)
    XCTAssertTrue(FileManager.default.fileExists(atPath: testModelDirectory.path))
    try fileManagerService.deleteModel(at: testModelDirectory)
    XCTAssertFalse(FileManager.default.fileExists(atPath: testModelDirectory.path))
  }

  func testModelConfigurationCreation() {
    let config = ModelConfiguration(
      name: "Test Model",
      hubId: "test/model",
      description: "A test model",
      modelType: .llm,
      gpuCacheLimit: 512 * 1024 * 1024,
      features: []
    )
    XCTAssertEqual(config.name, "Test Model")
    XCTAssertEqual(config.hubId, "test/model")
    XCTAssertEqual(config.description, "A test model")
  }

  func testModelMetadataExtraction() {
    let config = ModelConfiguration(
      name: "Qwen Test",
      hubId: "mlx-community/Qwen1.5-0.5B-Chat-4bit",
      description: "Test Qwen model"
    )
    XCTAssertEqual(config.architecture?.lowercased(), "qwen")
    XCTAssertEqual(config.quantization?.lowercased(), "4bit")
    XCTAssertEqual(config.parameters?.lowercased(), "0.5b")
  }

  /*
  func testMockDownloadModel() async throws {
      let downloader = ModelDownloader()
      let config = ModelConfiguration(
          name: "Test Model",
          hubId: "test-model",
          description: "A test model"
      )
      let url = try await downloader.downloadModel(config) { progress in
          XCTAssertGreaterThanOrEqual(progress, 0.0)
          XCTAssertLessThanOrEqual(progress, 1.0)
      }
      XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
      XCTAssertEqual(url.lastPathComponent, "test-model")
  }
  */

  func testLocalModelDirectoryCreation() throws {
    let fileManager = FileManagerService.shared
    let modelsDirectory = try fileManager.getModelsDirectory()
    let modelId = "unit-test-model"
    let modelDirectory = modelsDirectory.appendingPathComponent(modelId)
    if FileManager.default.fileExists(atPath: modelDirectory.path) {
      try fileManager.deleteModel(at: modelDirectory)
    }
    try FileManager.default.createDirectory(at: modelDirectory, withIntermediateDirectories: true)
    XCTAssertTrue(FileManager.default.fileExists(atPath: modelDirectory.path))
    try fileManager.deleteModel(at: modelDirectory)
    XCTAssertFalse(FileManager.default.fileExists(atPath: modelDirectory.path))
  }

  func testGetDownloadedModels() async throws {
    let downloader = ModelDownloader()
    let fileManager = FileManagerService.shared
    let modelsDirectory = try fileManager.getModelsDirectory()
    let modelId = "unit-test-downloaded-model"
    let modelDirectory = modelsDirectory.appendingPathComponent(modelId)
    if FileManager.default.fileExists(atPath: modelDirectory.path) {
      try fileManager.deleteModel(at: modelDirectory)
    }
    try FileManager.default.createDirectory(at: modelDirectory, withIntermediateDirectories: true)
    // Create dummy model files
    let files = ["config.json", "tokenizer.json", "model.safetensors"]
    for file in files {
      let fileURL = modelDirectory.appendingPathComponent(file)
      try "{}".write(to: fileURL, atomically: true, encoding: .utf8)
    }
    let models = try await downloader.getDownloadedModels()
    XCTAssertTrue(models.contains { $0.hubId == modelId })
    // Cleanup
    try fileManager.deleteModel(at: modelDirectory)
  }
}
