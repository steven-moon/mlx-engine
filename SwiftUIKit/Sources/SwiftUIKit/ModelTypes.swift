// ModelTypes.swift
// Centralized shared types for SwiftUIKit model-related views/components.
// All model-related types should be imported from this file.

import Foundation
import SwiftUI

/// Configuration for an AI model (name, hub ID, description, etc.).
public struct ModelConfiguration: Hashable, Sendable {
    public let name: String
    public let hubId: String
    public let description: String
    public let parameters: String?
    public let quantization: String?
    public let architecture: String?
    public init(name: String, hubId: String, description: String, parameters: String? = nil, quantization: String? = nil, architecture: String? = nil) {
        self.name = name
        self.hubId = hubId
        self.description = description
        self.parameters = parameters
        self.quantization = quantization
        self.architecture = architecture
    }
}

/// Registry for model compatibility and static configs.
public struct ModelRegistry {
    public static func isModelSupported(_ config: ModelConfiguration, ramGB: Double, platform: String) -> Bool {
        // Mock: always return true for now
        return true
    }
}

/// Summary metadata for a discovered model.
public struct ModelSummary: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let description: String
    public let parameters: String?
    public let quantization: String?
    public let architecture: String?
    public let imageURL: URL?
    public let downloads: Int
    public let likes: Int
    public let tags: [String]?
    public let createdAt: String?
    public let lastModified: String?
    public let isMLX: Bool
    public let author: String?
    public init(id: String, name: String, description: String, parameters: String? = nil, quantization: String? = nil, architecture: String? = nil, imageURL: URL? = nil, downloads: Int = 0, likes: Int = 0, tags: [String]? = nil, createdAt: String? = nil, lastModified: String? = nil, isMLX: Bool = true, author: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.parameters = parameters
        self.quantization = quantization
        self.architecture = architecture
        self.imageURL = imageURL
        self.downloads = downloads
        self.likes = likes
        self.tags = tags
        self.createdAt = createdAt
        self.lastModified = lastModified
        self.isMLX = isMLX
        self.author = author
    }
} 