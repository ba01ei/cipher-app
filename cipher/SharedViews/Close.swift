//
//  CloseButton.swift
//  cipher
//
//  Created by Bao Lei on 6/29/25.
//

import SwiftUI
import UIKit

struct Close: View {
  var body: some View {
    ZStack {
      Circle().foregroundStyle(Color.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .layoutPriority(0)
      
      Image(systemName: "x.circle.fill")
        .font(.title3)
        .tint(.black)
        .padding(1)
        .layoutPriority(1)
    }
    .padding(9)
  }
}
