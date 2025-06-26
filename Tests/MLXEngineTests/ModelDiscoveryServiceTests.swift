import XCTest
@testable import MLXEngine

final class ModelDiscoveryServiceTests: XCTestCase {
    func testSearchMLXModels() async throws {
        let results = try await ModelDiscoveryService.searchMLXModels(query: "mlx", limit: 10)
        // Should only return MLX-compatible models
        XCTAssertTrue(results.allSatisfy { $0.isMLX }, "All results should be MLX-compatible")
        // Should be sorted by downloads, then likes
        let downloads = results.map { $0.downloads }
        let sorted = downloads.sorted(by: >)
        XCTAssertEqual(downloads, sorted, "Results should be sorted by downloads descending")
        // At least one result should have non-empty metadata
        if let first = results.first {
            XCTAssertFalse(first.name.isEmpty)
            XCTAssertNotNil(first.architecture)
            XCTAssertNotNil(first.parameters)
        }
        // Should handle empty results gracefully
        let empty = try await ModelDiscoveryService.searchMLXModels(query: "nonexistent-model-query-xyz", limit: 5)
        XCTAssertTrue(empty.isEmpty)
    }

    func testModelRegistryDeviceRecommendation() async throws {
        // Simulate a device with 4GB RAM (e.g. iPhone SE)
        let ramGB = 4.0
        let platform = "iOS"
        let all = ModelRegistry.allModels
        let compatible = all.filter { ModelRegistry.isModelSupported($0, ramGB: ramGB, platform: platform) }
        XCTAssertFalse(compatible.isEmpty, "Should find at least one model for 4GB iOS device")
        for model in compatible {
            XCTAssertLessThan(model.estimatedMemoryGB, ramGB * 0.8, "Model should fit in RAM")
        }
    }

    func testModelRegistryMacRecommendation() async throws {
        // Simulate a Mac with 16GB RAM
        let ramGB = 16.0
        let platform = "macOS"
        let all = ModelRegistry.allModels
        let compatible = all.filter { ModelRegistry.isModelSupported($0, ramGB: ramGB, platform: platform) }
        XCTAssertFalse(compatible.isEmpty, "Should find at least one model for 16GB Mac")
        for model in compatible {
            XCTAssertLessThan(model.estimatedMemoryGB, ramGB * 0.8, "Model should fit in RAM")
        }
    }

    func testRecommendedModelsForCurrentDevice() async throws {
        let recommended = await ModelRegistry.recommendedModelsForCurrentDevice(limit: 2)
        XCTAssertFalse(recommended.isEmpty, "Should recommend at least one model for this device")
    }

    func testSearchCompatibleMLXModels() async throws {
        // Simulate a device with 8GB RAM, macOS
        let ramGB = 8.0
        let platform = "macOS"
        let results = try await ModelDiscoveryService.searchCompatibleMLXModels(query: "mlx", ramGB: ramGB, platform: platform, limit: 5)
        XCTAssertFalse(results.isEmpty, "Should find at least one compatible MLX model from Hugging Face")
        for summary in results {
            let config = ModelConfiguration(name: summary.name, hubId: summary.id, parameters: summary.parameters, quantization: summary.quantization, architecture: summary.architecture)
            XCTAssertTrue(ModelRegistry.isModelSupported(config, ramGB: ramGB, platform: platform), "Model should be supported on 8GB macOS")
        }
    }
} 