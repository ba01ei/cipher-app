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
    case gameLog(StoreOf<GameLogReducer>)
  }
  let id: String
  let detail: Detail
}

enum ErrorType: String, Sendable {
  case invalidGameId
}

let knownQuotesKey = "known_quotes"
let gameResultsKey = "game_results"

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
    case gameLogTapped
    case errorOccurred(ErrorType)
    
    case gameLog(GameLogReducer.Action)
  }
  
  @MainActor static func store() -> StoreOf<Self> {
    Store(initialState: State()) { state, action, send in
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
        state.alert = AlertContent(id: "join", message: "Enter Game ID", type: .input)
        return .none

      case .errorOccurred(let error):
        switch error {
        case .invalidGameId:
          state.alert = nil
          return .run { send in
            try? await Task.sleep(for: .milliseconds(300))
            await send(.presentRequested(PresentData(message: "Game ID must be a number")))
          }
        }
        
      case .gameLogTapped:
        state.sheet = SheetContent(id: "gameLog", detail: .gameLog(GameLogReducer.store().delegate({ childAction in
          send(.gameLog(childAction))
        })))
        return .none

      case .gameLog(let gameLogAction):
        switch gameLogAction {
        case .tapped(let game):
          state.sheet = nil
          if let time = game.time, Date().timeIntervalSince1970 - time <= 6 * 24 * 3600 {
            state.sheet = SheetContent(id: "game\(game.uuid)", detail: .web(URL(string: "https://cipherresult.val.run/?id=\(game.uuid)")!))
          } else {
            return .run { send in
              await send(.presentRequested(PresentData(message: "The game is no long available.")))
            }
          }

        default:
          break
        }
        return .none
        
      }
    }
  }
}
