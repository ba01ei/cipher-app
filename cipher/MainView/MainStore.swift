//
//  MainReducer.swift
//  cipher
//
//  Created by Bao Lei on 5/24/25.
//
import MiniRedux
import Foundation
import BridgingWebView

let startingUrl = URL(string: "https://cipher.lei.fyi")

struct AlertContent: Equatable, Sendable, Identifiable {
  enum AlertType: Equatable, Codable {
    case message
    case input
  }
  let id: String
  let message: String
  let type: AlertType
}

struct SheetContent: Sendable, Identifiable {
  enum Detail: Sendable {
    case web(URL)
    case shareURL(URL)
    case quotes(QuotesStore)
    case gameLog(GameLogStore)
    case gameCenterAchievements
    case gameCenterAuth
  }
  let id: String
  let detail: Detail
}

enum ErrorType: String, Sendable {
  case invalidGameId
}

let knownQuotesKey = "known_quotes"
let gameResultsKey = "game_results"

@Observable class MainStore: BaseStore<MainStore.Action> {
  var alert: AlertContent? = nil
  var sheet: SheetContent? = nil
  var bigSheet: SheetContent? = nil
  var alertInputText = ""
  var gameCenter: GameCenterStore?
  @ObservationIgnored let webCaller = WebCaller()
  
  enum Action: Sendable {
    case initialized
    case presentRequested(PresentData)
    case openLinkRequested(OpenLinkData)
    case shareLinkTapped
    case newGameTapped
    case quotesTapped
    case joinTapped
    case gameLogTapped
    case errorOccurred(ErrorType)
    case closeSheetTapped
    case alertOKButtonTapped
    case alertCancelButtonTapped
    case deeplinkRequested(URL)
    
    case quotes(QuotesStore.Action)
    case gameLog(GameLogStore.Action)
    case gameCenter(GameCenterStore.Action)
  }
  
  override init(delegatedActionHandler: ((Action) -> Void)? = nil) {
    super.init(delegatedActionHandler: delegatedActionHandler)
    send(.initialized)
  }
  
  override func reduce(_ action: Action) -> Effect<Action> {
    switch action {
    case .initialized:
      gameCenter = GameCenterStore() { [weak self] childAction in
        self?.send(.gameCenter(childAction))
      }
      return .none
      
    case .presentRequested(let presentData):
      sheet = nil
      bigSheet = nil
      alert = AlertContent(id: presentData.message, message: presentData.message, type: .message)
      return .none
      
    case .newGameTapped:
      return .run { [webCaller] send in
        do {
          let aliveResult = try await webCaller.sendMessageToWeb?(["action": "alive"]) as? [String: Any]
          if (aliveResult?["result"] as? Bool) == true {
            _ = try await webCaller.sendMessageToWeb?(["action": "startNewGame"])
            return
          }
        } catch {
          print("error: \(error)")
        }
        await webCaller.reloadUrl?(startingUrl)
      }

    case .openLinkRequested(let openLinkData):
      sheet = nil
      alert = nil
      bigSheet = SheetContent(id: "open" + openLinkData.url.absoluteString, detail: .web(openLinkData.url))
      return .none

    case .shareLinkTapped:
      if let url = webCaller.currentUrl?() {
        sheet = SheetContent(id: "share" + url.absoluteString, detail: .shareURL(url))
      }
      return .none

    case .quotesTapped:
      sheet = SheetContent(id: "quotes", detail: .quotes(QuotesStore() { [weak self] childAction in
        self?.send(.quotes(childAction))
      }))
      return .none

    case .joinTapped:
      alert = AlertContent(id: "join", message: "Enter Game ID", type: .input)
      return .none

    case .errorOccurred(let error):
      switch error {
      case .invalidGameId:
        alert = nil
        return .run { send in
          try? await Task.sleep(for: .milliseconds(300))
          await send(.presentRequested(PresentData(message: "Game ID must be a number")))
        }
      }
      
    case .gameLogTapped:
      sheet = SheetContent(id: "gameLog", detail: .gameLog(GameLogStore(gameCenterStore: gameCenter) { [weak self] childAction in
        self?.send(.gameLog(childAction))
      }))
      return .none
      
    case .closeSheetTapped:
      sheet = nil
      bigSheet = nil
      return .none
      
    case .alertOKButtonTapped:
      if alert?.id == "join" {
        let id = alertInputText.trimmingCharacters(in: .whitespacesAndNewlines)
        if id.allSatisfy({ $0.isNumber }) {
          webCaller.reloadUrl?(URL(string: "https://cipher.lei.fyi/\(alertInputText)")!)
        } else {
          send(.errorOccurred(.invalidGameId))
        }
        alertInputText = ""
      }
      return .none
      
    case .alertCancelButtonTapped:
      alertInputText = ""
      return .none
      
    case .deeplinkRequested(let url):
      return .run { [webCaller] _ in
        try? await Task.sleep(for: .milliseconds(500))
        await webCaller.reloadUrl?(url)
      }

    case .quotes(let quotesAction):
      switch quotesAction {
      case .closeTapped:
        sheet = nil
        bigSheet = nil
        return .none
        
      default:
        return .none
      }

    case .gameLog(let gameLogAction):
      switch gameLogAction {
      case .tapped(let game):
        sheet = nil
        bigSheet = nil
        if let time = game.time, Date().timeIntervalSince1970 - time <= 6 * 24 * 3600 {
          sheet = SheetContent(id: "game\(game.uuid)", detail: .web(URL(string: "https://cipherresult.val.run/?id=\(game.uuid)")!))
        } else {
          return .run { send in
            await send(.presentRequested(PresentData(message: "The game is no long available.")))
          }
        }
        
      case .closeTapped:
        sheet = nil
        bigSheet = nil

      default:
        break
      }
      return .none
      
    case .gameCenter(let gameCenterAction):
      switch gameCenterAction {
      case .achievementsTapped:
        sheet = nil
        bigSheet = SheetContent(id: "gameCenterAchievements", detail: .gameCenterAchievements)
        return .none
        
      case .authTapped:
        sheet = nil
        bigSheet = SheetContent(id: "gameCenterAuth", detail: .gameCenterAuth)
        return .none
        
      default:
        return .none
      }

    }
  }
}
