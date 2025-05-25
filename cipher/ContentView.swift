//
//  ContentView.swift
//  cipher
//
//  Created by Bao Lei on 5/24/25.
//

import MiniRedux
import SwiftUI

struct ContentView: View {
  @ObservedObject var store = MainReducer.store()

  let jsCaller = JavascriptCaller()
  var body: some View {
    WebView(url: URL(string: "https://cipher.lei.fyi"), javascriptCaller: jsCaller) { request in
      store.send(MainReducer.Action.bridgeRequestReceived(request))
      return [:]
    }
    .sheet(item: $store.state.sheet, content: { sheet in
      switch sheet.detail {
      case .web(let url):
        WebView(url: url, javascriptCaller: nil) { _ in return [:] }
      }
    })
    .alert(item: $store.state.alert) { alert in
      Alert(title: Text(alert.message))
    }
  }
}

#Preview {
  ContentView()
}
