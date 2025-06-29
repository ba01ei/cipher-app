//
//  GameLogView.swift
//  cipher
//
//  Created by Bao Lei on 6/8/25.
//

import MiniRedux
import SwiftUI

struct GameLogView: View {
  @ObservedObject var store: StoreOf<GameLogReducer>

  var body: some View {
    if store.state.games?.isEmpty == true {
      VStack {
        Image(systemName: "circle.slash").font(.system(size: 26))
          .padding()
        
        Text("No games yet.")
          .padding()
        Spacer()
      }
    } else if let games = store.state.games {
      List {
        HStack {
          Text("Game Log").font(.headline)
          Spacer()
#if targetEnvironment(macCatalyst)
          Button { store.send(.closeTapped) } label: {
            Image(systemName: "xmark.circle")
              .font(.title)
          }
#endif
        }
        if let gameCenterStore = store.state.gameCenter {
          GameCenterView(store: gameCenterStore)
        }
        ForEach(games) { game in
          HStack {
            Image(systemName: game.success ? "trophy.circle.fill" : "xmark.circle.fill")
              .font(.system(size: 20))
              .foregroundStyle(game.success ? Color.green : Color.red)
            VStack(alignment: .leading) {
              Text(game.id)
              if let time = game.time {
                Text(time.formatted)
                  .foregroundStyle(Color.secondary)
                  .font(.caption)
              }
            }
            Spacer()
            VStack(alignment: .trailing) {
              Text("\(game.timeTaken) sec")
              if game.hintCount > 0 {
                Text("\(game.hintCount) hint\(game.hintCount == 1 ? "" : "s")")
                  .foregroundStyle(Color.secondary)
                  .font(.caption)
              }
              if game.keywordRevealed {
                Text("Used keyword reveal")
                  .foregroundStyle(Color.secondary)
                  .font(.caption)
              }
            }
          }
          .contentShape(Rectangle())
          .onTapGesture {
            store.send(.tapped(game))
          }
        }
      }
    }
  }
}
