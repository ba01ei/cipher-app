//
//  GameCenterContainerView.swift
//  cipher
//
//  Created by Bao Lei on 6/29/25.
//

import UIKit
import GameKit
import SwiftUI

/// A SwiftUI view that wraps GKGameCenterViewController for presenting the Game Center authentication UI.
struct GameCenterContainerView: UIViewControllerRepresentable {
  var gameCenterVC: UIViewController?
  var dismissRequested: @MainActor () -> Void

  /// Creates and returns the GKGameCenterViewController.
  func makeUIViewController(context: Context) -> UIViewController {
    // Ensure we have a view controller to present.
    guard let vc = gameCenterVC else {
      // If no authenticationVC is provided, return a dummy view controller
      // or an error state, though in practice, authenticationVC should always be set.
      return UIViewController()
    }
    
    if let vc = vc as? GKGameCenterViewController {
      vc.gameCenterDelegate = context.coordinator
    }
    return vc
  }
  
  /// Updates the view controller. Not typically needed for GKGameCenterViewController.
  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    // No updates needed for GKGameCenterViewController once presented.
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator(dismissRequested: dismissRequested)
  }
  
  @MainActor class Coordinator: NSObject, GKGameCenterControllerDelegate {
    private var dismissRequested: @MainActor () -> Void
    
    init(dismissRequested: @escaping @MainActor () -> Void) {
      self.dismissRequested = dismissRequested
    }

    nonisolated func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
      MainActor.assumeIsolated {
        dismissRequested()
      }
    }
  }
}

