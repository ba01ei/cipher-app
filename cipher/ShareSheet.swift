import SwiftUI
import UIKit

/// A SwiftUI wrapper for UIActivityViewController to present a share sheet.
struct ShareSheet: UIViewControllerRepresentable {
  let activityItems: [Any]
  let applicationActivities: [UIActivity]?
  @Environment(\.presentationMode) var presentationMode // To dismiss the sheet
  
  /// Creates and configures the UIActivityViewController.
  /// - Parameter context: The context for creating the view controller.
  /// - Returns: A UIActivityViewController instance.
  func makeUIViewController(context: Context) -> UIActivityViewController {
    let controller = UIActivityViewController(
      activityItems: activityItems,
      applicationActivities: applicationActivities
    )
    
    // Set a completion handler to dismiss the sheet after sharing or cancellation.
    controller.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
      // You can add custom logic here based on the completion status.
      if let error = error {
        print("Share sheet error: \(error.localizedDescription)")
      }
      // Dismiss the UIActivityViewController
      presentationMode.wrappedValue.dismiss()
    }
    
    return controller
  }
  
  /// Updates the UIActivityViewController (not typically needed for a simple share sheet).
  /// - Parameters:
  ///   - uiViewController: The UIActivityViewController instance.
  ///   - context: The context for updating the view controller.
  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    // No update logic needed for a simple share sheet
  }
}
