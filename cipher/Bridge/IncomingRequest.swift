//
//  IncomingRequest.swift
//  cipher
//
//  Created by Bao Lei on 5/24/25.
//

enum BridgeAction: String, Codable, Sendable {
  case present
}

struct BridgeData: Codable, Sendable {
  var message: String?
}

struct IncomingRequest: Codable, Sendable {
  var action: BridgeAction
  var data: BridgeData
}
