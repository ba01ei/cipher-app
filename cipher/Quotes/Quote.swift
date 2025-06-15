//
//  Quote.swift
//  cipher
//
//  Created by Bao Lei on 6/15/25.
//

struct Quote: Codable, Equatable {
  let text: String
  let by: String
  var deleted: Bool?
  
  init(string: String) {
    deleted = false
    let split = string.split(separator: "-")
    if split.count == 1 {
      text = string
      by = ""
    } else {
      text = split[0..<split.count - 1].joined(separator: "-").trimmingCharacters(in: .whitespacesAndNewlines)
      by = split.last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
  }
  
  var toText: String {
    return "\(text) - \(by)"
  }
}

extension String {
  var toQuote: Quote {
    return Quote(string: self)
  }
}

extension [Quote] {
  func deduped() -> [Quote] {
    var seen = Set<String>()
    return filter { seen.insert($0.text).inserted }
  }
}
