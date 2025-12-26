import Foundation
import MiniRedux
import GameKit

@Observable class GameLogStore: BaseStore<GameLogStore.Action> {
  var games: [FinishData]?
  let gameCenter: GameCenterStore?
  
  enum Action {
    case initialized
    case gamesLoaded([FinishData])
    case tapped(FinishData)
    case closeTapped
  }
  
  init(gameCenterStore: GameCenterStore?, delegatedActionHandler: ((Action) -> Void)? = nil) {
    self.gameCenter = gameCenterStore
    super.init(delegatedActionHandler: delegatedActionHandler)
    send(.initialized)
  }
  
  override func reduce(_ action: Action) -> Effect<Action> {
    switch action {
    case .initialized:
      return .run { send in
        let games: [FinishData] = Storage.value(for: gameResultsKey) ?? []
        await send(.gamesLoaded(games))
      }

    case .gamesLoaded(let games):
      self.games = games

      if gameCenter?.isAuthenticated == true {
        return .run { _ in
          AchievementsHelper.reportAchievements(from: games)
        }
      } else {
        return .none
      }

    case .tapped, .closeTapped:
      // delegated to parent
      return .none

    }
  }
}
