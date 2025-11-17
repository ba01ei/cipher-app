//
//  ContentView.swift
//  cipher
//
//  Created by Bao Lei on 5/24/25.
//

import BridgingWebView
import MiniRedux
import SwiftUI
import GameKit

let startingUrl = URL(string: "https://cipher.lei.fyi")

struct ContentView: View {
  @ObservedObject var store = MainReducer.store()
  @Environment(\.displayScale) var displayScale

  let webCaller: WebCaller

  var body: some View {
    NavigationStack {
      GeometryReader { geometry in
        VStack(spacing: 0) {
          webView
          Color.accentColor.frame(height: 1 / displayScale).frame(maxWidth: .infinity)
        }
        .toolbar { bottomBar }
      }
      
    }
    .sheet(item: $store.state.sheet, content: { sheet in
      sheetView(sheet)
    })
    .fullScreenCover(item: $store.state.bigSheet, content: { sheet in
      sheetView(sheet)
    })
    .alert(store.state.alert?.message ?? "", isPresented: Binding(get: {
      store.state.alert != nil
    }, set: { shown in
      if !shown {
        store.state.alert = nil
      }
    })) { [alertId = store.state.alert?.id] in
      if store.state.alert?.type == .input {
        TextField("", text: $store.state.alertInputText)
          .keyboardType(.numberPad)
      }
      Button("OK") {
        if alertId == "join" {
          let id = store.state.alertInputText.trimmingCharacters(in: .whitespacesAndNewlines)
          if id.allSatisfy({ $0.isNumber }) {
            webCaller.reloadUrl?(URL(string: "https://cipher.lei.fyi/\(store.state.alertInputText)")!)
          } else {
            store.send(.errorOccurred(.invalidGameId))
          }
          store.state.alertInputText = ""
        }
      }
      if store.state.alert?.type == .input {
        Button("Cancel", role: .cancel) {
          store.state.alertInputText = ""
        }
      }
    }
  }

  var webView: some View {
    BridgingWebView(url: startingUrl, webCaller: webCaller) { request in
      do {
        return try await store.handleBridgeRequest(request)
      } catch {
        assertionFailure("Bridge error: \(error)")
        return [:]
      }
    }
  }

  @ToolbarContentBuilder var bottomBar: some ToolbarContent {
    ToolbarItem(placement: .bottomBar) {
      HStack(spacing: 0) {
        bottomBarButton("New game", "arrow.clockwise") {
          Task {
            do {
              let aliveResult = try await webCaller.sendMessageToWeb?(["action": "alive"]) as? [String: Any]
              if (aliveResult?["result"] as? Bool) == true {
                _ = try await webCaller.sendMessageToWeb?(["action": "startNewGame"])
                return
              }
            } catch {
              print("error: \(error)")
            }
            webCaller.reloadUrl?(startingUrl)
          }
        }
        bottomBarButton("Join", "person.badge.plus") {
          store.send(.joinTapped)
        }
        bottomBarButton("Share", "square.and.arrow.up") {
          if let url = webCaller.currentUrl?() {
            store.send(.shareLinkTapped(url))
          }
        }
        bottomBarButton("Quotes", "book") {
          store.send(.quotesTapped)
        }
        bottomBarButton("Games", "chart.bar") {
          store.send(.gameLogTapped)
        }
      }
      .padding(.top, 2)
    }
  }
  
  func bottomBarButton(_ title: String, _ sfSymbol: String, action: @escaping @MainActor () -> Void) -> some View {
    Button(action: action) {
      VStack(spacing: 4) {
        Image(systemName: sfSymbol).frame(height: 18)
        Text(title).font(.caption)
      }
      .foregroundStyle(.primary)
      .frame(width: 60)
    }
  }
  
  @ViewBuilder func sheetView(_ sheet: SheetContent) -> some View {
    switch sheet.detail {
    case .web(let url):
      ZStack(alignment: .topLeading) {
        BridgingWebView(url: url, webCaller: nil) { _ in return [:] }
        Button { store.send(.closeSheetTapped) } label: {
          Close()
        }
      }
      
    case .shareURL(let url):
      ShareSheet(activityItems: [url], applicationActivities: nil)

    case .quotes(let quotesStore):
      QuotesView(store: quotesStore)

    case .gameLog(let gameLogStore):
      GameLogView(store: gameLogStore)

    case .gameCenterAchievements:
      GameCenterContainerView(gameCenterVC: GKGameCenterViewController(state: .achievements)) {
        store.send(.closeSheetTapped)
      }
      
    case .gameCenterAuth:
      if let vc = store.state.gameCenter?.state.authViewController {
        GameCenterContainerView(gameCenterVC: vc) {
          store.send(.closeSheetTapped)
        }
      } else {
        VStack {
          Text("Sorry, something went wrong and Game Center is not available")
          Button("Close") {
            store.send(.closeSheetTapped)
          }
        }
      }
      
    }
  }
}

