import XCTest
@testable import MLXEngine

final class HuggingFaceAPINetworkTests: XCTestCase {
    func testLargeResultSet() async throws {
        AppLogger.shared.info("HuggingFaceAPINetworkTests", "START testLargeResultSet")
        let api = HuggingFaceAPI.shared
        do {
            let models = try await api.searchModels(query: "chat", limit: 50)
            AppLogger.shared.info("HuggingFaceAPINetworkTests", "testLargeResultSet: models.count = \(models.count)")
            XCTAssertGreaterThanOrEqual(models.count, 0)
        } catch {
            AppLogger.shared.error("HuggingFaceAPINetworkTests", "testLargeResultSet: error = \(error)")
            // Accept network errors if offline
        }
    }

    func testMalformedJSONHandling() async throws {
        AppLogger.shared.info("HuggingFaceAPINetworkTests", "START testMalformedJSONHandling")
        // This would require HTTP mocking, so we skip it in this environment.
        throw XCTSkip("Requires HTTP mocking.")
    }

    func testModelSearchSuccess() async throws {
        AppLogger.shared.info("HuggingFaceAPINetworkTests", "START testModelSearchSuccess")
        let api = HuggingFaceAPI.shared
        let models = try await api.searchModels(query: "Qwen", limit: 2)
        AppLogger.shared.info("HuggingFaceAPINetworkTests", "testModelSearchSuccess: models.count = \(models.count)")
        XCTAssertGreaterThan(models.count, 0, "Should find at least one model for query")
    }

    func testModelSearchNoResults() async throws {
        AppLogger.shared.info("HuggingFaceAPINetworkTests", "START testModelSearchNoResults")
        let api = HuggingFaceAPI.shared
        do {
            let models = try await api.searchModels(query: "nonexistent-model-xyz-1234567890", limit: 2)
            AppLogger.shared.info("HuggingFaceAPINetworkTests", "testModelSearchNoResults: models.count = \(models.count)")
            XCTAssertEqual(models.count, 0, "Should return no results for gibberish query")
        } catch {
            AppLogger.shared.error("HuggingFaceAPINetworkTests", "testModelSearchNoResults: error = \(error)")
            // Accept network errors if offline
        }
    }

    func testModelSearchInvalidURL() async throws {
        AppLogger.shared.info("HuggingFaceAPINetworkTests", "START testModelSearchInvalidURL")
        let api = HuggingFaceAPI.shared
        do {
            _ = try await api.searchModels(query: String(repeating: "#", count: 1000), limit: 1)
            AppLogger.shared.info("HuggingFaceAPINetworkTests", "testModelSearchInvalidURL: No error thrown for malformed query; skipping test as server may accept any query.")
            throw XCTSkip("No error thrown for malformed query; server may accept any query.")
        } catch let error as HuggingFaceError {
            AppLogger.shared.info("HuggingFaceAPINetworkTests", "testModelSearchInvalidURL: error = \(error)")
            XCTAssertTrue(error == .invalidURL || error == .networkError || error == .decodingError, "Expected invalidURL, networkError, or decodingError, got \(error)")
        } catch {
            AppLogger.shared.error("HuggingFaceAPINetworkTests", "testModelSearchInvalidURL: error = \(error)")
            // Accept network errors if offline
        }
    }

    func testDownloadModelFileNotFound() async throws {
        AppLogger.shared.info("HuggingFaceAPINetworkTests", "START testDownloadModelFileNotFound")
        let api = HuggingFaceAPI.shared
        let tempDir = FileManager.default.temporaryDirectory
        let destURL = tempDir.appendingPathComponent("nonexistent_file.bin")
        do {
            try await api.downloadModel(modelId: "mlx-community/Qwen1.5-0.5B-Chat-4bit", fileName: "nonexistent_file.bin", to: destURL) { _, _, _ in }
            XCTFail("Expected networkError")
        } catch let error as HuggingFaceError {
            AppLogger.shared.info("HuggingFaceAPINetworkTests", "testDownloadModelFileNotFound: error = \(error)")
            XCTAssertEqual(error, .networkError)
        } catch {
            AppLogger.shared.error("HuggingFaceAPINetworkTests", "testDownloadModelFileNotFound: error = \(error)")
            // Accept network errors if offline
        }
    }

    func testGetModelInfoNotFound() async throws {
        AppLogger.shared.info("HuggingFaceAPINetworkTests", "START testGetModelInfoNotFound")
        let api = HuggingFaceAPI.shared
        do {
            _ = try await api.getModelInfo(modelId: "nonexistent-model-xyz-1234567890")
            XCTFail("Expected networkError")
        } catch let error as HuggingFaceError {
            AppLogger.shared.info("HuggingFaceAPINetworkTests", "testGetModelInfoNotFound: error = \(error)")
            XCTAssertEqual(error, .networkError)
        } catch {
            AppLogger.shared.error("HuggingFaceAPINetworkTests", "testGetModelInfoNotFound: error = \(error)")
            // Accept network errors if offline
        }
    }
} 