//
//  ContentView.swift
//  cipher
//
//  Created by Bao Lei on 5/24/25.
//

import MiniRedux
import SwiftUI

let startingUrl = URL(string: "https://cipher.lei.fyi")

struct ContentView: View {
  @ObservedObject var store = MainReducer.store()
  @Environment(\.displayScale) var displayScale

  let webCaller = WebCaller()
  var body: some View {
    VStack(spacing: 0) {
      webView
      Color.black.frame(height: 1 / displayScale).frame(maxWidth: .infinity)
      bottomBar
    }
    .sheet(item: $store.state.sheet, content: { sheet in
      switch sheet.detail {
      case .web(let url):
        WebView(url: url, webCaller: nil) { _ in return [:] }
      }
    })
    .alert(item: $store.state.alert) { alert in
      Alert(title: Text(alert.message))
    }
  }

  var webView: some View {
    WebView(url: startingUrl, webCaller: webCaller) { request in
      store.send(MainReducer.Action.bridgeRequestReceived(request))
      return [:]
    }
  }

  var bottomBar: some View {
    HStack(alignment: .lastTextBaseline) {
      bottomBarButton("New game", "arrow.clockwise") {
        webCaller.reloadUrl?(startingUrl)
      }
      bottomBarButton("Share", "square.and.arrow.up") {
        
      }
      bottomBarButton("Quotes", "book") {
        
      }
      bottomBarButton("Stats", "chart.bar") {
        
      }
    }
    .frame(maxWidth: .infinity)
  }
  
  func bottomBarButton(_ title: String, _ sfSymbol: String, action: @escaping @MainActor () -> Void) -> some View {
    Button(action: action) {
      VStack {
        Image(systemName: sfSymbol)
        Text(title).font(.caption)
      }
    }
    .foregroundStyle(.black)
    .padding(.top, 8)
    .frame(maxWidth: .infinity)
  }
}

#Preview {
  ContentView()
}
