//
//  GameCenter.swift
//  cipher
//
//  Created by Bao Lei on 6/29/25.
//

import MiniRedux
import GameKit

extension GKLocalPlayer: @unchecked @retroactive Sendable {}

@Observable class GameCenterStore: BaseStore<GameCenterStore.Action> {
  var isAuthenticated = false
  var authViewController: UIViewController?
  var error: String?
  var canShowGameCenter: Bool {
    return isAuthenticated || (authViewController != nil)
  }
  
  enum Action {
    case initialized
    case authViewPresentationRequested(UIViewController)
    case gameCenterAuthStateUpdated(Bool, Error?)
    case achievementsTapped
    case authTapped(UIViewController)
  }
  
  override init(delegatedActionHandler: ((Action) -> Void)? = nil) {
    super.init(delegatedActionHandler: delegatedActionHandler)
    send(.initialized)
  }
  
  override func reduce(_ action: Action) -> Effect<Action> {
    switch action {
    case .initialized:
      return .run { _ in
        GKLocalPlayer.local.authenticateHandler = { viewController, error in
          Task { @MainActor [weak self] in
            self?.send(.gameCenterAuthStateUpdated(GKLocalPlayer.local.isAuthenticated, error))
            if let viewController {
              self?.send(.authViewPresentationRequested(viewController))
            }
          }
        }
      }
      
    case .authViewPresentationRequested(let viewController):
      authViewController = viewController
      return .none

    case .gameCenterAuthStateUpdated(let authenticated, let error):
      isAuthenticated = authenticated
      self.error = error?.localizedDescription
      return .none
      
    case .achievementsTapped:
      return .none

    case .authTapped:
      // delegate to parent
      return .none
    }
  }
}
