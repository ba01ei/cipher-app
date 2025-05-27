//
//  QuotesView.swift
//  cipher
//
//  Created by Bao Lei on 5/26/25.
//

import MiniRedux
import SwiftUI

struct QuotesView: View {
  @ObservedObject var store: StoreOf<QuotesReducer>
  @Environment(\.openURL) var openURL

  var body: some View {
    if store.state.quotes?.isEmpty == true {
      VStack {
        Image(systemName: "text.page.slash").font(.system(size: 26))
          .padding()
        
        Text("You haven't decoded any quotes yet.\n\nComplete a game to unlock some ancient wisdom.")
          .padding()
        Spacer()
      }
    } else if let quotes = store.state.quotes {
      List {
        Text("Decoded Quotes").font(.headline) + Text(" — \(quotes.count)")
        ForEach(quotes, id: \.self) { quote in
          Button {
            if let url = store.urlForQuote(quote) {
              openURL(url)
            }
          } label: {
            Text(quote)
          }
        }
      }
    }
  }
}

#Preview {
  QuotesView(store: QuotesReducer.store())
}
