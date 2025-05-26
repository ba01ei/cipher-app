//
//  MainStore+HandleBridgeRequest.swift
//  cipher
//
//  Created by Bao Lei on 5/25/25.
//

import MiniRedux

extension StoreOf<MainReducer> {
  func handleBridgeRequest(_ request: any Sendable) async throws -> [String: any Sendable] {
    guard let json = request as? [String: Any] else {
      return [:]
    }
    guard let actionJson = json["action"] as? String,
          let bridgeAction = BridgeAction(rawValue: actionJson),
          let dataJson = json["data"] else {
      print("missing action or data from bridge message: \(json)")
      return [:]
    }
    
    switch bridgeAction {
    case .present:
      let presentData = try fromJSON(dataJson, to: PresentData.self)
      send(.presentRequested(presentData))
      
    case .openLink:
      let openLinkData = try fromJSON(dataJson, to: OpenLinkData.self)
      send(.openLinkRequested(openLinkData))
      
    case .appendKnownQuote:
      let newQuote = try fromJSON(dataJson, to: AppendKnownQuoteData.self)
      var array: [String] = Storage.value(for: knownQuotesKey) ?? []
      array.insert(newQuote.quote, at: 0)
      Storage.set(array, for: knownQuotesKey)
      
    case .requestKnownQuotes:
      let quotes: [String] = Storage.value(for: knownQuotesKey) ?? []
      print("known quotes are \(quotes)")
      return ["quotes": quotes]

    }
    return [:]
  }
}

