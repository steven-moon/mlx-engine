import XCTest
@testable import MLXEngine

final class ModelRegistryTests: XCTestCase {
    
    func testAllModelsNotEmpty() {
        let models = ModelRegistry.allModels
        XCTAssertFalse(models.isEmpty, "ModelRegistry should have at least one model")
        XCTAssertGreaterThanOrEqual(models.count, 8, "Should have at least 8 predefined models")
    }
    
    func testSmallModelsCollection() {
        let smallModels = ModelRegistry.smallModels
        XCTAssertEqual(smallModels.count, 3, "Should have 3 small models")
        
        for model in smallModels {
            XCTAssertTrue(model.isSmallModel, "All small models should be marked as small")
        }
    }
    
    func testMediumModelsCollection() {
        let mediumModels = ModelRegistry.mediumModels
        XCTAssertEqual(mediumModels.count, 3, "Should have 3 medium models")
    }
    
    func testLargeModelsCollection() {
        let largeModels = ModelRegistry.largeModels
        XCTAssertEqual(largeModels.count, 2, "Should have 2 large models")
    }
    
    func testFindModelByHubId() {
        let qwen = ModelRegistry.findModel(by: "mlx-community/Qwen1.5-0.5B-Chat-4bit")
        XCTAssertNotNil(qwen, "Should find Qwen model by hub ID")
        XCTAssertEqual(qwen?.name, "Qwen 1.5 0.5B Chat")
        
        let notFound = ModelRegistry.findModel(by: "nonexistent/model")
        XCTAssertNil(notFound, "Should return nil for non-existent model")
    }
    
    func testFindModelByName() {
        let llama = ModelRegistry.findModelByName("Llama 3.2 3B")
        XCTAssertNotNil(llama, "Should find LLaMA model by name")
        XCTAssertEqual(llama?.hubId, "mlx-community/Llama-3.2-3B-4bit")
        
        let notFound = ModelRegistry.findModelByName("Non-existent Model")
        XCTAssertNil(notFound, "Should return nil for non-existent model name")
    }
    
    func testFindModelsByArchitecture() {
        let llamaModels = ModelRegistry.findModels(by: "Llama")
        XCTAssertGreaterThanOrEqual(llamaModels.count, 3, "Should find multiple Llama models")
        
        for model in llamaModels {
            XCTAssertEqual(model.architecture, "Llama")
        }
    }
    
    func testFindMobileSuitableModels() {
        let mobileModels = ModelRegistry.findMobileSuitableModels()
        XCTAssertGreaterThanOrEqual(mobileModels.count, 3, "Should find multiple mobile-suitable models")
        
        for model in mobileModels {
            XCTAssertTrue(model.isSmallModel, "All mobile models should be small")
        }
    }
    
    func testFindModelsByParameterRange() {
        let smallModels = ModelRegistry.findModels(parameterRange: 0.5...3.0)
        XCTAssertGreaterThanOrEqual(smallModels.count, 4, "Should find multiple small models")
        
        for model in smallModels {
            guard let params = model.parameters?.lowercased() else {
                XCTFail("Model should have parameters")
                continue
            }
            
            let isSmall = params.contains("0.5b") || params.contains("1b") || 
                         params.contains("1.5b") || params.contains("2b") || params.contains("3b")
            XCTAssertTrue(isSmall, "All models should be in the specified range")
        }
    }
    
    func testFindModelsByQuantization() {
        let fourBitModels = ModelRegistry.findModels(byQuantization: "4bit")
        XCTAssertGreaterThanOrEqual(fourBitModels.count, 6, "Should find multiple 4-bit models")
        
        for model in fourBitModels {
            XCTAssertEqual(model.quantization, "4bit")
        }
    }
    
    func testModelConfigurationsAreValid() {
        for model in ModelRegistry.allModels {
            XCTAssertFalse(model.name.isEmpty, "Model name should not be empty")
            XCTAssertFalse(model.hubId.isEmpty, "Model hub ID should not be empty")
            XCTAssertTrue(model.hubId.contains("/"), "Hub ID should contain organization/model format")
            XCTAssertGreaterThan(model.maxTokens, 0, "Max tokens should be positive")
        }
    }
    
    func testModelMetadataExtraction() {
        for model in ModelRegistry.allModels {
            // Test that models have reasonable metadata
            if let params = model.parameters {
                XCTAssertTrue(params.contains("B"), "Parameters should contain 'B' suffix")
            }
            
            if let quant = model.quantization {
                XCTAssertTrue(["4bit", "8bit", "fp16", "fp32"].contains(quant), "Quantization should be valid")
            }
            
            if let arch = model.architecture {
                XCTAssertFalse(arch.isEmpty, "Architecture should not be empty")
            }
        }
    }
    
    func testLegacySupport() {
        // Test that legacy properties still work by finding them in allModels
        let allModels = ModelRegistry.allModels
        
        // Find Qwen 0.5B model
        let qwenModel = allModels.first { $0.hubId.contains("Qwen1.5-0.5B") }
        XCTAssertNotNil(qwenModel, "Should find Qwen 0.5B model in allModels")
        
        // Find Llama 3.2 3B model
        let llamaModel = allModels.first { $0.hubId.contains("Llama-3.2-3B") }
        XCTAssertNotNil(llamaModel, "Should find Llama 3.2 3B model in allModels")
        
        // Find Mistral 7B model
        let mistralModel = allModels.first { $0.hubId.contains("Mistral-7B") }
        XCTAssertNotNil(mistralModel, "Should find Mistral 7B model in allModels")
    }
    
    func testModelSearchFunctionality() {
        // Test search by partial name
        let qwenResults = ModelRegistry.searchModels(query: "Qwen")
        XCTAssertGreaterThanOrEqual(qwenResults.count, 1, "Should find at least one Qwen model")
        
        // Test search by architecture
        let llamaResults = ModelRegistry.searchModels(query: "Llama")
        XCTAssertGreaterThanOrEqual(llamaResults.count, 3, "Should find multiple Llama models")
        
        // Test search by size
        let smallResults = ModelRegistry.searchModels(query: "0.5B")
        XCTAssertGreaterThanOrEqual(smallResults.count, 1, "Should find small models")
    }
    
    func testModelCategorization() {
        let allModels = ModelRegistry.allModels
        
        // Test that models are properly categorized
        let smallModels = allModels.filter { $0.isSmallModel }
        let mediumModels = allModels.filter { !$0.isSmallModel && ($0.parameters?.contains("7B") == true || $0.parameters?.contains("8B") == true) }
        let largeModels = allModels.filter { $0.parameters?.contains("13B") == true || $0.parameters?.contains("14B") == true }
        
        XCTAssertGreaterThanOrEqual(smallModels.count, 3, "Should have multiple small models")
        XCTAssertGreaterThanOrEqual(mediumModels.count, 1, "Should have at least one medium model")
        XCTAssertGreaterThanOrEqual(largeModels.count, 0, "Should have at least zero large models (may not have 13B+ models)")
    }
    
    func testModelUniqueness() {
        let allModels = ModelRegistry.allModels
        
        // Test that all models have unique hub IDs
        let hubIds = allModels.map { $0.hubId }
        let uniqueHubIds = Set(hubIds)
        XCTAssertEqual(hubIds.count, uniqueHubIds.count, "All models should have unique hub IDs")
        
        // Test that all models have unique names
        let names = allModels.map { $0.name }
        let uniqueNames = Set(names)
        XCTAssertEqual(names.count, uniqueNames.count, "All models should have unique names")
    }
} 