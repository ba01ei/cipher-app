//
//  GameCenterContainerView.swift
//  cipher
//
//  Created by Bao Lei on 6/29/25.
//

import UIKit
import SwiftUI

/// A SwiftUI view that wraps GKGameCenterViewController for presenting the Game Center authentication UI.
struct GameCenterContainerView: UIViewControllerRepresentable {
  var gameCenterVC: UIViewController?

  /// Creates and returns the GKGameCenterViewController.
  func makeUIViewController(context: Context) -> UIViewController {
    // Ensure we have a view controller to present.
    guard let vc = gameCenterVC else {
      // If no authenticationVC is provided, return a dummy view controller
      // or an error state, though in practice, authenticationVC should always be set.
      return UIViewController()
    }
    return vc
  }
  
  /// Updates the view controller. Not typically needed for GKGameCenterViewController.
  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    // No updates needed for GKGameCenterViewController once presented.
  }
}

