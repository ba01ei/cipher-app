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
        Text("Game Log").font(.headline)
        ForEach(games) { game in
          Text(game.id)
            .onTapGesture {
              print("tapped")
            }
        }
      }
    }
  }
}
