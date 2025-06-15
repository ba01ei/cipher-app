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
    var quotes: [Quote]?
    var notDeleted: [Quote] {
      return quotes?.filter({ quote in
        quote.deleted != true
      }) ?? []
    }
  }
  
  enum Action {
    case initialized
    case quotesLoaded([Quote])
    case deleteQuote(Quote)
  }
  
  @MainActor static func store() -> StoreOf<Self> {
    return Store(initialState: State(), initialAction: .initialized) { state, action, _ in
      switch action {
      case .initialized:
        return .run { send in
          var quotes: [Quote]? = Storage.value(for: knownQuotesKey)
          if quotes == nil {
            let strings: [String]? = Storage.value(for: knownQuotesKey)
            quotes = strings?.map(\.toQuote) ?? []
          }
          let set = NSOrderedSet(array: (quotes ?? []).map(\.text))
          if set.count != quotes?.count, let deduped = quotes?.deduped() {
            Storage.set(deduped, for: knownQuotesKey)
            quotes = deduped
          }
          await send(.quotesLoaded(quotes ?? []))
        }

      case .quotesLoaded(let quotes):
        state.quotes = quotes
        return .none
        
      case .deleteQuote(let quote):
        for i in 0..<(state.quotes?.count ?? 0) {
          if state.quotes?[i].text == quote.text {
            state.quotes?[i].deleted = true
          }
        }
        Storage.set(state.quotes ?? [], for: knownQuotesKey)
        return .none

      }
    }
  }
}

extension StoreOf<QuotesReducer> {
  func urlForQuote(_ quote: Quote) -> URL? {
    if quote.by.isEmpty {
      return nil
    }
    var urlComp = URLComponents(string: "https://en.wikipedia.org/w/index.php")
    urlComp?.queryItems = [
      URLQueryItem(name: "search", value: String(quote.by).removingParentheses().replacing(" ", with: "+"))
    ]
    return urlComp?.url
  }
}
