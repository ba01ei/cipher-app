//
//  QuotesReducer.swift
//  cipher
//
//  Created by Bao Lei on 5/26/25.
//

import Foundation
import MiniRedux

struct QuotesReducer: Reducer {
  struct State: Equatable {
    var quotes: [String]?
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
          var quotes: [String] = Storage.value(for: knownQuotesKey) ?? []
          let set = NSOrderedSet(array: quotes)
          if set.count != quotes.count, let deduped = set.array as? [String] {
            Storage.set(deduped, for: knownQuotesKey)
            quotes = deduped
          }
          await send(.quotesLoaded(quotes))
        }

      case .quotesLoaded(let quotes):
        state.quotes = quotes
        return .none

      }
    }
  }
}

extension StoreOf<QuotesReducer> {
  func urlForQuote(_ quote: String) -> URL? {
    guard let author = quote.split(separator: "-").last else {
      return nil
    }
    var urlComp = URLComponents(string: "https://en.wikipedia.org/w/index.php")
    urlComp?.queryItems = [
      URLQueryItem(name: "search", value: String(author).removingParentheses().replacing(" ", with: "+"))
    ]
    return urlComp?.url
  }
}
