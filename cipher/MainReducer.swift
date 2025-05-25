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
  }
  let id: String
  let detail: Detail
}

struct MainReducer: Reducer {
  struct State: Equatable, Sendable {
    var alert: AlertContent? = nil
    var sheet: SheetContent? = nil
  }
  
  enum Action: Sendable {
    case bridgeRequestReceived(any Sendable)
    case presentRequested(PresentData)
    case openLinkRequested(OpenLinkData)
  }
  
  @MainActor static func store() -> StoreOf<Self> {
    Store(initialState: State()) { state, action, _ in
      switch action {
      case .bridgeRequestReceived(let request):
        return .run { send in
          guard let json = request as? [String: Any] else {
            return
          }
          do {
            guard let actionJson = json["action"] as? String,
                  let bridgeAction = BridgeAction(rawValue: actionJson),
                  let dataJson = json["data"] else {
              print("missing action or data from bridge message: \(json)")
              return
            }

            switch bridgeAction {
            case .present:
              let presentData = try fromJSON(dataJson, to: PresentData.self)
              await send(.presentRequested(presentData))
              
            case .openLink:
              let openLinkData = try fromJSON(dataJson, to: OpenLinkData.self)
              await send(.openLinkRequested(openLinkData))

            }
          } catch {
            print("error: \(error)")
          }
        }
        
      case .presentRequested(let presentData):
        state.alert = AlertContent(id: presentData.message, message: presentData.message)
        return .none

      case .openLinkRequested(let openLinkData):
        state.sheet = SheetContent(id: openLinkData.url.absoluteString, detail: .web(openLinkData.url))
        return .none

      }
    }
  }
}
