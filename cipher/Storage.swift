//
//  Storage.swift
//  cipher
//
//  Created by Bao Lei on 5/25/25.
//

import Foundation

struct Storage {
  static func set<T: Codable>(_ item: T, for key: String) {
    do {
      let data = try JSONEncoder().encode(item)
      let compressedData = try (data as NSData).compressed(using: .lzfse)
      NSUbiquitousKeyValueStore.default.set(compressedData, forKey: key)
    } catch {
      print("encode error: \(error)")
    }
  }
  
  static func value<T: Codable>(for key: String) -> T? {
    guard let compressed = NSUbiquitousKeyValueStore.default.data(forKey: key) else {
      return nil
    }
    do {
      let data = try (compressed as NSData).decompressed(using: .lzfse)
      return try JSONDecoder().decode(T.self, from: data as Data)
    } catch {
      print("decode error: \(error)")
      return nil
    }
  }
}
