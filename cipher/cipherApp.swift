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
  let webCaller = WebCaller()
  var body: some Scene {
    WindowGroup {
      ContentView(webCaller: webCaller)
        .onOpenURL { url in
          // Handle universal links here
          Task {
            try? await Task.sleep(for: .milliseconds(500))
            webCaller.reloadUrl?(url)
          }
        }
    }
  }
}
