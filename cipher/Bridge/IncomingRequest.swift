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
}

struct PresentData: Codable, Sendable {
  var message: String
}

struct OpenLinkData: Codable, Sendable {
  var url: URL
}
