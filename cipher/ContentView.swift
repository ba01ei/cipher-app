//
//  ContentView.swift
//  cipher
//
//  Created by Bao Lei on 5/24/25.
//

import SwiftUI

struct ContentView: View {
  let jsCaller = JavascriptCaller()
  var body: some View {
    WebView(url: URL(string: "https://cipher.lei.fyi"), javascriptCaller: jsCaller) { request in
      print("received request: \(request)")
      Task { @MainActor in
        try? await jsCaller.callJavaScript?(["message": "hi"])
      }
      return ["hello": "world"]
    }
  }
}

#Preview {
  ContentView()
}
