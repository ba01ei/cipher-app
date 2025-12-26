//
//  QuotesReducer.swift
//  cipher
//
//  Created by Bao Lei on 5/26/25.
//

import Foundation
import MiniRedux

@Observable class QuotesStore: BaseStore<QuotesStore.Action> {
  var quotes: [Quote]?
  var notDeleted: [Quote] {
    return quotes?.filter({ quote in
      quote.deleted != true
    }) ?? []
  }
  
  enum Action {
    case initialized
    case quotesLoaded([Quote])
    case deleteQuote(Quote)
    case closeTapped
  }
  
  override init(delegatedActionHandler: ((Action) -> Void)? = nil) {
    super.init(delegatedActionHandler: delegatedActionHandler)
    send(.initialized)
  }
  
  override func reduce(_ action: Action) -> Effect<Action> {
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
      self.quotes = quotes
      return .none
      
    case .deleteQuote(let quote):
      for i in 0..<(quotes?.count ?? 0) {
        if quotes?[i].text == quote.text {
          quotes?[i].deleted = true
        }
      }
      Storage.set(quotes ?? [], for: knownQuotesKey)
      return .none

    case .closeTapped:
      // delegated
      return .none
      
    }
  }
}

extension QuotesStore {
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
