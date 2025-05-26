//
//  IncomingRequest.swift
//  cipher
//
//  Created by Bao Lei on 5/24/25.
//

import Foundation

enum BridgeAction: String, Codable, Sendable {
  case present
  case openLink
  case appendKnownQuote
  case requestKnownQuotes
}

struct PresentData: Codable, Sendable {
  let message: String
}

struct OpenLinkData: Codable, Sendable {
  let url: URL
}

struct AppendKnownQuoteData: Codable, Sendable {
  let quote: String
}
