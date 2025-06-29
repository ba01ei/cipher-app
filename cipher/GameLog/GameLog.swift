import Foundation
import MiniRedux
import GameKit

struct GameLogReducer: Reducer {
  struct State: Equatable {
    var games: [FinishData]?
    var gameCenter: StoreOf<GameCenter>?
  }
  
  enum Action {
    case initialized
    case gamesLoaded([FinishData])
    case tapped(FinishData)
    case closeTapped
  }
  
  @MainActor static func store(gameCenter: StoreOf<GameCenter>?) -> StoreOf<Self> {
    return Store(initialState: State(gameCenter: gameCenter), initialAction: .initialized) { state, action, _ in
      switch action {
      case .initialized:
        return .run { send in
          let games: [FinishData] = Storage.value(for: gameResultsKey) ?? []
          await send(.gamesLoaded(games))
        }

      case .gamesLoaded(let games):
        state.games = games

        if state.gameCenter?.state.isAuthenticated == true {
          return .run { _ in
            let achievements = AchievementsHelper.achievements(from: games).map {
              let achievement = GKAchievement(identifier: $0.rawValue)
              achievement.percentComplete = 100.0
              achievement.showsCompletionBanner = true
              return achievement
            }
            GKAchievement.report(achievements) { error in
              if let error {
                print("Error reporting achievement: \(error.localizedDescription)")
              }
            }
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
}
