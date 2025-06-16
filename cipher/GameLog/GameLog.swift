import Foundation
import MiniRedux

struct GameLogReducer: Reducer {
  struct State: Equatable {
    var games: [FinishData]?
  }
  
  enum Action {
    case initialized
    case gamesLoaded([FinishData])
    case tapped(FinishData)
    case closeTapped
  }
  
  @MainActor static func store() -> StoreOf<Self> {
    return Store(initialState: State(), initialAction: .initialized) { state, action, _ in
      switch action {
      case .initialized:
        return .run { send in
          let games: [FinishData] = Storage.value(for: gameResultsKey) ?? []
          await send(.gamesLoaded(games))
        }

      case .gamesLoaded(let games):
        state.games = games
        return .none

      case .tapped, .closeTapped:
        // delegated to parent
        return .none

      }
    }
  }
}
