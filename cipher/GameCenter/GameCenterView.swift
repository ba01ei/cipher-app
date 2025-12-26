//
//  GameCenterView.swift
//  cipher
//
//  Created by Bao Lei on 6/29/25.
//

import SwiftUI
import MiniRedux

struct GameCenterView: View {
  let store: GameCenterStore
  
  var body: some View {
    HStack {
      if store.isAuthenticated {
        Button {
          store.send(.achievementsTapped)
        } label: {
          HStack {
            Image(systemName: "trophy")
            Text("Achievements")
          }
        }
      } else if let vc = store.authViewController {
        Button("Login to Game Center") {
          store.send(.authTapped(vc))
        }
      } else {
        Text("")
      }
    }
  }
}
