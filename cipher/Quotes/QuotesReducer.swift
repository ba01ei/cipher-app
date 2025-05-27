//
//  QuotesReducer.swift
//  cipher
//
//  Created by Bao Lei on 5/26/25.
//

import MiniRedux

struct QuotesReducer: Reducer {
  struct State: Equatable {
    var quotes: [String] = []
  }
  
  enum Action {
    case initialized
    case quotesLoaded([String])
  }
  
  @MainActor static func store() -> StoreOf<Self> {
    return Store(initialState: State(), initialAction: .initialized) { state, action, _ in
      switch action {
      case .initialized:
        return .run { send in
          let quotes: [String] = Storage.value(for: knownQuotesKey) ?? []
          await send(.quotesLoaded(quotes))
        }
        
      case .quotesLoaded(let quotes):
        state.quotes = quotes
        return .none

      }
    }
  }
}
