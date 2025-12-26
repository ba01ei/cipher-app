//
//  QuotesView.swift
//  cipher
//
//  Created by Bao Lei on 5/26/25.
//

import MiniRedux
import SwiftUI

struct QuotesView: View {
  let store: QuotesStore
  @Environment(\.openURL) var openURL

  var body: some View {
    if store.quotes?.isEmpty == true {
      VStack {
        Image(systemName: "text.page.slash").font(.system(size: 26))
          .padding()
        
        Text("You haven't decoded any quotes yet.\n\nComplete a game to unlock some ancient wisdom.")
          .padding()
        Spacer()
      }
    } else if !store.notDeleted.isEmpty {
      List {
        HStack {
          Text("Decoded Quotes").font(.headline) + Text(" — \(store.notDeleted.count)")
          Spacer()
#if targetEnvironment(macCatalyst)
          Button { store.send(.closeTapped) } label: {
            Image(systemName: "xmark.circle")
              .font(.title)
              .tint(.primary)
          }
#endif
        }
        ForEach(store.notDeleted, id: \.text) { quote in
          VStack {
            Text(quote.text).foregroundColor(Color.primary) + Text(" - " + quote.by).foregroundColor(.secondary)
          }
            .onTapGesture {
              if let url = store.urlForQuote(quote) {
                openURL(url)
              }
            }
            .swipeActions {
              Button("Delete", role: .destructive) {
                store.send(.deleteQuote(quote))
              }
              .tint(.red)
            }
        }
      }
    }
  }
}

#Preview {
  QuotesView(store: QuotesStore())
}
