//
//  HuggingFaceAPI+macOS.swift
//  MLXEngine
//
//  macOS-only extensions for HuggingFaceAPI
//

#if os(macOS)
  import Foundation
  import CoreFoundation

  extension HuggingFaceAPI {
    private static var macOSProxyDictionary: [AnyHashable: Any] {
      [
        kCFNetworkProxiesHTTPEnable: true,
        kCFNetworkProxiesHTTPSEnable: true,
      ]
    }
    public func loadHuggingFaceToken() -> String? {
      let tokenPaths = [
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(
          ".cache/huggingface/token"),
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(
          ".huggingface/token"),
      ]
      for path in tokenPaths {
        if let data = try? Data(contentsOf: path), let token = String(data: data, encoding: .utf8) {
          return token.trimmingCharacters(in: .whitespacesAndNewlines)
        }
      }
      return nil
    }
    // Patch the initializer to set the proxy dictionary
    public convenience init(macOSWithProxy: Bool) {
      self.init()
      let configuration = URLSessionConfiguration.default
      configuration.connectionProxyDictionary = Self.macOSProxyDictionary
    }
  }
#endif
