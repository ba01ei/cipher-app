//
//  GameCenter.swift
//  cipher
//
//  Created by Bao Lei on 6/29/25.
//

import MiniRedux
import GameKit

extension GKLocalPlayer: @unchecked @retroactive Sendable {}

struct GameCenter: Reducer {
  struct State: Equatable {
    var isAuthenticated = false
    var authViewController: UIViewController?
    var error: String?
  }
  
  enum Action {
    case initialized
    case authViewPresentationRequested(UIViewController)
    case gameCenterAuthStateUpdated(Bool, Error?)
    case achievementsTapped
    case authTapped(UIViewController)
  }
  
  @MainActor static func store() -> StoreOf<Self> {
    return Store(initialState: State(), initialAction: .initialized, debug: true) { state, action, send in
      switch action {
      case .initialized:
        return .run { _ in
          GKLocalPlayer.local.authenticateHandler = { viewController, error in
            Task { @MainActor in
              send(.gameCenterAuthStateUpdated(GKLocalPlayer.local.isAuthenticated, error))
              if let viewController {
                send(.authViewPresentationRequested(viewController))
              }
            }
          }
        }
        
      case .authViewPresentationRequested(let viewController):
        state.authViewController = viewController
        return .none

      case .gameCenterAuthStateUpdated(let authenticated, let error):
        state.isAuthenticated = authenticated
        state.error = error?.localizedDescription
        return .none
        
      case .achievementsTapped:
        return .none

      case .authTapped:
        // delegate to parent
        return .none
      }
    }
  }
}
