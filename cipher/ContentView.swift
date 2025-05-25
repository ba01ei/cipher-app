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
//    .alert(store.state.alertMessage ?? "", isPresented: Binding(get: {
//      store.state.alertMessage != nil
//    }, set: { presented in
//      if !presented {
//        store.state.alertMessage = nil
//      }
//    })) {
//      // no op
//    }
    .sheet(item: $store.state.sheet) { sheetContent in
      switch sheetContent.type {
      case .alert:
        VStack(spacing: 20) {
          Text(sheetContent.message)
            .font(.subheadline)
          Button {
            store.send(.alertDismissTapped)
          } label: {
            Text("OK")
          }
          .keyboardShortcut(.defaultAction)
          .buttonStyle(.bordered)
        }
        .padding()
      }
    }
  }
}

#Preview {
  ContentView()
}
