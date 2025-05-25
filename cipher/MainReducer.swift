//
//  MainReducer.swift
//  cipher
//
//  Created by Bao Lei on 5/24/25.
//
import MiniRedux

struct SheetContent: Equatable, Sendable, Identifiable {
  enum SheetType {
    case alert
  }
  let id: String
  let type: SheetType
  let message: String
}

struct MainReducer: Reducer {
  struct State: Equatable, Sendable {
    var sheet: SheetContent? = nil
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
          state.sheet = SheetContent(id: message, type: .alert, message: message)
        }
        return .none

      case .alertDismissTapped:
        state.sheet = nil
        return .none
      }
    }
  }
}
