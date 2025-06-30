//
//  MainStore+HandleBridgeRequest.swift
//  cipher
//
//  Created by Bao Lei on 5/25/25.
//

import Foundation
import MiniRedux
import GameKit

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
      var array: [Quote]? = Storage.value(for: knownQuotesKey)
      if array == nil {
        let stringArray: [String]? = Storage.value(for: knownQuotesKey)
        array = stringArray?.map(\.toQuote) ?? []
      }
      array?.insert(newQuote.quote.toQuote, at: 0)
      Storage.set(array ?? [], for: knownQuotesKey)
      
    case .requestKnownQuotes:
      let quotes: [Quote] = Storage.value(for: knownQuotesKey) ?? []
      return ["quotes": quotes.map(\.toText)]

    case .finish:
      var finishData = try fromJSON(dataJson, to: FinishData.self)
      let now = Date().timeIntervalSince1970
      finishData.time = now
      var array: [FinishData] = Storage.value(for: gameResultsKey) ?? []
      array.insert(finishData, at: 0)
      // this is the full array, we can check for achievements
      if GKLocalPlayer.local.isAuthenticated {
        AchievementsHelper.reportAchievements(from: array)
      }
      Storage.set(array, for: gameResultsKey)
    }
    return [:]
  }
}

