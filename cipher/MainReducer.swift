//
//  MainReducer.swift
//  cipher
//
//  Created by Bao Lei on 5/24/25.
//
import MiniRedux
import Foundation

struct AlertContent: Equatable, Sendable, Identifiable {
  let id: String
  let message: String
}

struct SheetContent: Equatable, Sendable, Identifiable {
  enum Detail: Equatable, Sendable {
    case web(URL)
    case shareURL(URL)
  }
  let id: String
  let detail: Detail
}

let knownQuotesKey = "known_quotes"

struct MainReducer: Reducer {
  struct State: Equatable, Sendable {
    var alert: AlertContent? = nil
    var sheet: SheetContent? = nil
  }
  
  enum Action: Sendable {
    case presentRequested(PresentData)
    case openLinkRequested(OpenLinkData)
    case shareLinkTapped(URL)
  }
  
  @MainActor static func store() -> StoreOf<Self> {
    Store(initialState: State()) { state, action, _ in
      switch action {
      case .presentRequested(let presentData):
        state.alert = AlertContent(id: presentData.message, message: presentData.message)
        return .none

      case .openLinkRequested(let openLinkData):
        state.sheet = SheetContent(id: "open" + openLinkData.url.absoluteString, detail: .web(openLinkData.url))
        return .none

      case .shareLinkTapped(let url):
        state.sheet = SheetContent(id: "share" + url.absoluteString, detail: .shareURL(url))
        return .none

      }
    }
  }
}
