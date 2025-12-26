//
//  iOSHelpers.swift
//  cipher
//
//  Created by Bao Lei on 12/25/25.
//

public var iOS26: Bool {
  if #available(iOS 26, macOS 26, *) {
    return true
  } else {
    return false
  }
}
