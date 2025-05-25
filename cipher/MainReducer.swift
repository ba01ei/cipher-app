//
//  MainReducer.swift
//  cipher
//
//  Created by Bao Lei on 5/24/25.
//
import MiniRedux

struct AlertContent: Equatable, Sendable, Identifiable {
  let id: String
  let message: String
}

struct MainReducer: Reducer {
  struct State: Equatable, Sendable {
    var alert: AlertContent? = nil
  }
  
  enum Action: Sendable {
    case bridgeRequestReceived(any Sendable)
    case presentRequested(String?)
    case alertDismissTapped
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
            let incomingRequest = try fromJSON(json, to: IncomingRequest.self)
            switch incomingRequest.action {
            case .present:
              await send(.presentRequested(incomingRequest.data.message))
            }
          } catch {
            print("error: \(error)")
          }
        }
        
      case .presentRequested(let message):
        if let message {
          state.alert = AlertContent(id: message, message: message)
        }
        return .none

      case .alertDismissTapped:
        state.alert = nil
        return .none
      }
    }
  }
}
