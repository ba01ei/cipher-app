//
//  StringHelpers.swift
//
//  Created by Bao Lei on 6/8/25.
//
extension String {
  func removingParentheses() -> String {
    return self.replacingOccurrences(of: "\\s*\\([^)]*\\)", with: "", options: .regularExpression)
  }
}

