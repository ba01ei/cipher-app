//
//  FinishData+Display.swift
//  cipher
//
//  Created by Bao Lei on 12/31/25.
//

import SwiftUI

extension FinishData {
  var iconSFSymbol: String {
    success ? (hardMode == true ? "medal.fill" : "trophy.circle.fill") : "xmark.circle.fill"
  }
  
  var displayColor: Color {
    success ? (hardMode == true ? Color.yellow : Color.green) : Color.red
  }
}
