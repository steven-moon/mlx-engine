import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif

func sha256Hex(data: Data) -> String {
    #if canImport(CryptoKit)
    let digest = SHA256.hash(data: data)
    return digest.map { String(format: "%02x", $0) }.joined()
    #else
    // Fallback: Not available, return empty string
    return ""
    #endif
} 