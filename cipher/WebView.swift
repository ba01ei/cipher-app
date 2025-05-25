//
//  WebView.swift
//  cipher
//
//  Created by Bao Lei on 5/24/25.
//


import SwiftUI
import UIKit
import WebKit

public struct WebView: UIViewRepresentable {
  let url: URL?
  let bridgeName: String
  let webToNativeFunctionName: String
  let nativeToWebFunctionName: String
  private var onJavaScriptCall: (Any) async -> [String: Any]?

  /// Create a WebView that supports bidirectional respondable bridging activities.
  /// - note
  /// To send a message from native to web, call `await javascriptCaller.callJavascript(json)`.
  /// On the web side, handle that by setting `window.${bridgeName}.${nativeToWebFuncationName} = { ... }`
  /// To send a message from web to native, call `await window.${bridgeName}.webToNativeFunctionName(json)`
  /// On the native side, handle that in `onJavascriptCall`
  public init(
    url: URL?,
    bridgeName: String = "WebNativeBridge",
    webToNativeFunctionName: String = "webToNative",
    nativeToWebFunctionName: String = "nativeToWeb",
    javascriptCaller: JavascriptCaller,
    onJavascriptCall: @escaping ((any Sendable) async -> [String: Any]?)) {
      self.url = url
      self.bridgeName = bridgeName
      self.webToNativeFunctionName = webToNativeFunctionName
      self.nativeToWebFunctionName = nativeToWebFunctionName
      self.onJavaScriptCall = onJavascriptCall
      javascriptCaller.callJavaScript = callJavaScript
  }
  
  // Reference to the coordinator for calling JavaScript from native
  @State private var coordinator: Coordinator?

  public func makeUIView(context: Context) -> WKWebView {
    let coordinator = context.coordinator
    Task {
      self.coordinator = coordinator
    }
    
    let configuration = WKWebViewConfiguration()
    
    // Add user content controller for JavaScript communication
    let userContentController = WKUserContentController()
    userContentController.addUserScript(WKUserScript(source: JavaScriptBridge.setupScript(bridgeName: bridgeName, webToNativeFunctionName: webToNativeFunctionName), injectionTime: .atDocumentStart, forMainFrameOnly: true))
    configuration.userContentController = userContentController
    userContentController.addScriptMessageHandler(coordinator, contentWorld: .page, name: bridgeName)
    
    let webView = WKWebView(frame: .zero, configuration: configuration)
    coordinator.webView = webView
    #if DEBUG
    if #available(iOS 16.4, macCatalyst 16.4, *) {
      webView.isInspectable = true
    }
    #endif

    // Load content
    if let url = url {
      let request = URLRequest(url: url)
      webView.load(request)
    }
    return webView
  }
  
  public func updateUIView(_ uiView: WKWebView, context: Context) {
  }
  
  public func makeCoordinator() -> Coordinator {
    Coordinator(onJavaScriptCall: onJavaScriptCall)
  }
  
  // call JavaScript from native code
  @MainActor private func callJavaScript(parameters: [String: any Sendable]) async throws -> Any? {
    return try await coordinator?.callJavaScript(js: "return await window.\(bridgeName).\(nativeToWebFunctionName)(data)", parameters: parameters)
  }
}

@MainActor public final class JavascriptCaller {
  public fileprivate(set) var callJavaScript: (@MainActor (_ parameters: [String: any Sendable]) async throws -> (any Sendable)?)? = nil
  
  public init() {}
}

// MARK: - Coordinator
extension WebView {
  public class Coordinator: NSObject, WKScriptMessageHandlerWithReply {
    private var onJavaScriptCall: (Any) async throws -> [String: any Sendable]?
    weak var webView: WKWebView?
    
    init(onJavaScriptCall: @escaping (Any) async -> [String: any Sendable]?) {
      self.onJavaScriptCall = onJavaScriptCall
    }
    
    // Handle calls from JavaScript
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage, replyHandler: @escaping @MainActor (Any?, String?) -> Void) {
      Task {
        do {
          let result = try await onJavaScriptCall(message.body)
          replyHandler(result, nil)
        } catch {
          replyHandler(nil, "\(error)")
        }
      }
    }
    

    // Call JavaScript from native
    func callJavaScript(js: String, parameters: [String: any Sendable]) async throws -> Any? {
      return try await webView?.callAsyncJavaScript(js, arguments: parameters, in: nil, contentWorld: .page)
    }
  }
}

// MARK: - JavaScript Bridge Helper
struct JavaScriptBridge {
  static func setupScript(bridgeName: String, webToNativeFunctionName: String) -> String {
    return """
      window.\(bridgeName) = {
        \(webToNativeFunctionName): function (data) {
          return window.webkit.messageHandlers.\(bridgeName).postMessage(data);
        },
      };
    """
  }
}


