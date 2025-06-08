import Foundation
import MiniRedux

struct GameLogReducer: Reducer {
  struct State: Equatable {
    var games: [FinishData]?
  }
  
  enum Action {
    case initialized
    case gamesLoaded([FinishData])
  }
  
  @MainActor static func store() -> StoreOf<Self> {
    return Store(initialState: State(), initialAction: .initialized) { state, action, _ in
      switch action {
      case .initialized:
        return .run { send in
          let games: [FinishData] = Storage.value(for: gameResultsKey) ?? []
          let currentTime = Date().timeIntervalSince1970
          let filtered = games.filter { game in
            currentTime - (game.time ?? 0) < 5 * 24 * 3600
          }
          if games.count != filtered.count {
            Storage.set(filtered, for: gameResultsKey)
          }
          await send(.gamesLoaded(filtered))
        }

      case .gamesLoaded(let games):
        state.games = games
        return .none

      }
    }
  }
}
