//
//  GameLogView.swift
//  cipher
//
//  Created by Bao Lei on 6/8/25.
//

import MiniRedux
import SwiftUI

struct GameLogView: View {
  let store: GameLogStore

  var body: some View {
    NavigationStack {
      Group {
        if store.games?.isEmpty == true {
          VStack {
            Image(systemName: "circle.slash").font(.system(size: 26))
              .padding()
            
            Text("No games yet.")
              .padding()
            Spacer()
          }
        } else if let games = store.games {
          List {
            if let gameCenterStore = store.gameCenter, gameCenterStore.canShowGameCenter {
              GameCenterView(store: gameCenterStore)
            }
            ForEach(games) { game in
              HStack {
                Image(systemName: game.hardMode == true ? "medal.fill" : (game.success ? "trophy.circle.fill" : "xmark.circle.fill"))
                  .font(.system(size: 20))
                  .foregroundStyle(game.hardMode == true ? Color.yellow : (game.success ? Color.green : Color.red))
                VStack(alignment: .leading) {
                  Text(game.display)
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
                  if game.hardMode == true {
                    Text("Hard Mode")
                      .foregroundStyle(Color.orange)
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
      .navigationTitle("Game Log")
      .toolbar {
#if targetEnvironment(macCatalyst)
        ToolbarItem(placement: .topBarTrailing) {
          Button { store.send(.closeTapped) } label: {
            Image(systemName: "xmark.circle")
              .font(.title)
              .tint(.primary)
          }
        }
#endif
      }
    }
  }
}
