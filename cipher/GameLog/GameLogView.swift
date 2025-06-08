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
        
        Text("No games in the last 5 days.")
          .padding()
        Spacer()
      }
    } else if let games = store.state.games {
      List {
        Text("Recent Games").font(.headline) + Text(" — \(games.count)")
        ForEach(games, id: \.uuid) { game in
          Button {
            
          } label: {
            Text(game.uuid)
          }
        }
      }
    }
  }
}
