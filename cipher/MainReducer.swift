//
//  MainReducer.swift
//  cipher
//
//  Created by Bao Lei on 5/24/25.
//
import MiniRedux
import Foundation

struct AlertContent: Equatable, Sendable, Identifiable {
  enum AlertType: Equatable, Codable {
    case message
    case input
  }
  let id: String
  let message: String
  let type: AlertType
}

struct SheetContent: Equatable, Sendable, Identifiable {
  enum Detail: Equatable, Sendable {
    case web(URL)
    case shareURL(URL)
    case quotes(StoreOf<QuotesReducer>)
  }
  let id: String
  let detail: Detail
}

let knownQuotesKey = "known_quotes"

struct MainReducer: Reducer {
  struct State: Equatable, Sendable {
    var alert: AlertContent? = nil
    var sheet: SheetContent? = nil
    var alertInputText = ""
  }
  
  enum Action: Sendable {
    case presentRequested(PresentData)
    case openLinkRequested(OpenLinkData)
    case shareLinkTapped(URL)
    case quotesTapped
    case joinTapped
  }
  
  @MainActor static func store() -> StoreOf<Self> {
    Store(initialState: State()) { state, action, _ in
      switch action {
      case .presentRequested(let presentData):
        state.alert = AlertContent(id: presentData.message, message: presentData.message, type: .message)
        return .none

      case .openLinkRequested(let openLinkData):
        state.sheet = SheetContent(id: "open" + openLinkData.url.absoluteString, detail: .web(openLinkData.url))
        return .none

      case .shareLinkTapped(let url):
        state.sheet = SheetContent(id: "share" + url.absoluteString, detail: .shareURL(url))
        return .none

      case .quotesTapped:
        state.sheet = SheetContent(id: "quotes", detail: .quotes(QuotesReducer.store()))
        return .none

      case .joinTapped:
        state.alert = AlertContent(id: "join", message: "Enter game id", type: .input)
        return .none

      }
    }
  }
}
