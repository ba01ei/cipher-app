//
//  ContentView.swift
//  cipher
//
//  Created by Bao Lei on 5/24/25.
//

import BridgingWebView
import MiniRedux
import SwiftUI

let startingUrl = URL(string: "https://cipher.lei.fyi")

struct ContentView: View {
  @ObservedObject var store = MainReducer.store()
  @Environment(\.displayScale) var displayScale

  let webCaller = WebCaller()
  var body: some View {
    GeometryReader { geometry in
      VStack(spacing: 0) {
        webView
        Color.black.frame(height: 1 / displayScale).frame(maxWidth: .infinity)
        bottomBar
          /// for device without bottom safe area inset, add some padding so the bottom bars are not touching the bottom of the screen
          .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 8)
      }
    }
    .ignoresSafeArea(.keyboard, edges: .bottom)
    .sheet(item: $store.state.sheet, content: { sheet in
      switch sheet.detail {
      case .web(let url):
        BridgingWebView(url: url, webCaller: nil) { _ in return [:] }
        
      case .shareURL(let url):
        ShareSheet(activityItems: [url], applicationActivities: nil)

      case .quotes(let quotesStore):
        QuotesView(store: quotesStore)

      }
    })
    .alert(item: $store.state.alert) { alert in
      Alert(title: Text(alert.message))
    }
  }

  var webView: some View {
    BridgingWebView(url: startingUrl, webCaller: webCaller) { request in
      return try await store.handleBridgeRequest(request)
    }
  }

  var bottomBar: some View {
    HStack(alignment: .lastTextBaseline) {
      bottomBarButton("New game", "arrow.clockwise") {
        Task {
          do {
            _ = try await webCaller.sendMessageToWeb?(["action": "startNewGame"])
          } catch {
            print("error: \(error)")
          }
        }
      }
      bottomBarButton("Share", "square.and.arrow.up") {
        if let url = webCaller.currentUrl?() {
          store.send(.shareLinkTapped(url))
        }
      }
      bottomBarButton("Quotes", "book") {
        store.send(.quotesTapped)
      }
      bottomBarButton("Stats", "chart.bar") {
        
      }
    }
    .frame(maxWidth: .infinity)
  }
  
  func bottomBarButton(_ title: String, _ sfSymbol: String, action: @escaping @MainActor () -> Void) -> some View {
    Button(action: action) {
      VStack(spacing: 4) {
        Image(systemName: sfSymbol).font(.system(size: 20))
        Text(title).font(.caption)
      }
    }
    .foregroundStyle(.primary)
    .padding(.top, 8)
    .frame(maxWidth: .infinity)
  }
}

#Preview {
  ContentView()
}
