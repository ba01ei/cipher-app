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
  @State var store = MainStore()
  @Environment(\.displayScale) var displayScale

  let webCaller: WebCaller

  var body: some View {
    NavigationStack {
      webView
        .ignoresSafeArea()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar { bottomBar }
        .sheet(item: $store.sheet, content: { sheet in
          sheetView(sheet)
        })
        .fullScreenCover(item: $store.bigSheet, content: { sheet in
          sheetView(sheet)
        })
        .alert(store.alert?.message ?? "", isPresented: Binding(get: {
          store.alert != nil
        }, set: { shown in
          if !shown {
            store.alert = nil
          }
        })) { [alertId = store.alert?.id] in
          if store.alert?.type == .input {
            TextField("", text: $store.alertInputText)
              .keyboardType(.numberPad)
          }
          Button("OK") {
            if alertId == "join" {
              let id = store.alertInputText.trimmingCharacters(in: .whitespacesAndNewlines)
              if id.allSatisfy({ $0.isNumber }) {
                webCaller.reloadUrl?(URL(string: "https://cipher.lei.fyi/\(store.alertInputText)")!)
              } else {
                store.send(.errorOccurred(.invalidGameId))
              }
              store.alertInputText = ""
            }
          }
          if store.alert?.type == .input {
            Button("Cancel", role: .cancel) {
              store.alertInputText = ""
            }
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
    if iOS26 {
      ToolbarItem(placement: .bottomBar) {
        newGameButton
      }
      ToolbarItem(placement: .bottomBar) {
        joinButton
      }
      ToolbarItem(placement: .bottomBar) {
        shareButton
      }
      ToolbarItem(placement: .bottomBar) {
        quotesButton
      }
      ToolbarItem(placement: .bottomBar) {
        gamesButton
      }
    } else {
      ToolbarItem(placement: .bottomBar){
        HStack {
          newGameButton
          joinButton
          shareButton
          quotesButton
          gamesButton
        }
      }
    }
  }
  
  var newGameButton: some View {
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
  }
  
  var joinButton: some View {
    bottomBarButton("Join", "person.badge.plus") {
      store.send(.joinTapped)
    }
  }
  
  var shareButton: some View {
    bottomBarButton("Share", "square.and.arrow.up") {
      if let url = webCaller.currentUrl?() {
        store.send(.shareLinkTapped(url))
      }
    }
  }
  
  var quotesButton: some View {
    bottomBarButton("Quotes", "book") {
      store.send(.quotesTapped)
    }
  }
  
  var gamesButton: some View {
    bottomBarButton("Games", "chart.bar") {
      store.send(.gameLogTapped)
    }
  }

  func bottomBarButton(_ title: String, _ sfSymbol: String, action: @escaping @MainActor () -> Void) -> some View {
    Button(action: action) {
      VStack(spacing: 4) {
        Image(systemName: sfSymbol).font(.system(size: 16)).frame(height: 18)
        Text(title).font(.caption)
      }
      .foregroundStyle(.primary)
    }
    .padding(.vertical, 5)
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
      if let vc = store.gameCenter?.authViewController {
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

