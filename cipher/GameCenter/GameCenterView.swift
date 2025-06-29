//
//  GameCenterView.swift
//  cipher
//
//  Created by Bao Lei on 6/29/25.
//

import SwiftUI
import MiniRedux

struct GameCenterView: View {
  @ObservedObject var store: StoreOf<GameCenter>
  
  var body: some View {
    HStack {
      if store.state.isAuthenticated {
        Button("Achievements") {
          store.send(.achievementsTapped)
        }
      } else if let vc = store.state.authViewController {
        Button("Login to Game Center") {
          store.send(.authTapped(vc))
        }
      } else {
        Text("")
      }
    }
  }
}
