//
//  cipherApp.swift
//  cipher
//
//  Created by Bao Lei on 5/24/25.
//

import SwiftUI
import BridgingWebView

@main
struct cipherApp: App {
  let store = MainStore()
  var body: some Scene {
    WindowGroup {
      MainView(store: store)
        .onOpenURL { url in
          store.send(.deeplinkRequested(url))
        }
    }
  }
}
