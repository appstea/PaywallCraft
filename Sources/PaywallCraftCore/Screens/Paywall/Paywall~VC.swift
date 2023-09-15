//
//  Paywall~VC.swift
//
//  Created by dDomovoj on 6/9/22.
//

import UIKit

import StoreKit
import SafariServices

import RevenueCat

import UIBase
import PaywallCraftResources

extension Paywall {

  @objc(PaywallViewController)
  open class ViewController: UIBase.ViewController {

    public let config: Config
    public let screen: any IPaywallScreen
    public let source: any IPaywallSource

    private var onEvent: Paywall.OnEvents?
    private var streamContinuation: Paywall.EventStream.Continuation?

    // MARK: - Readonly

    var analytics: Analytics.Service? { .shared }
    var paywall: Paywall.Service {
      guard let instance = Paywall.Service.shared else {
        preconditionFailure("Must have paywall service")
      }
      return instance
    }

    // MARK: - Init

    public init(config: Config, source: some IPaywallSource, screen: some IPaywallScreen,
                onEvent: Paywall.OnEvents? = nil) {
      self.config = config
      self.source = source
      self.screen = screen
      self.onEvent = onEvent
      super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder: NSCoder) { return nil }

    // MARK: - Lifecycle

    override open func viewDidLoad() {
      super.viewDidLoad()
      Notification.Paywall.Update
        .observe { [weak self] _ in self?.didUpdatePaywallStatus() }
        .bind(to: self)
      analytics?.sendPaywallEvent(.upsellShown(source: source, screen: screen))
    }

    open func didUpdatePaywallStatus() { }

    // MARK: - Internal
    
    func createEvent() -> Paywall.Event { paywall.createEvent() }
    
    // MARK: - Public
    
    @MainActor
    open func events() -> Paywall.EventStream {
      AsyncStream { [weak self] in self?.streamContinuation = $0 }
    }
    
    open func handleEventAndCloseIfFinal(_ e: Paywall.Event) {
      onEvent?(e)
      streamContinuation?.yield(e)
      if e.isFinal {
        streamContinuation?.finish()
        streamContinuation = nil
      }
    }

    public func purchase(_ product: StoreProduct?) {
      guard let product = product
      else {
        showErrorAlert(.productNotSpecified)
        return
      }
      
      analytics?.sendPaywallEvent(
        .productSelected(source: source, screen: screen, productId: product.productIdentifier))
      
      paywall.purchase(product, screen: screen, source: source) { [weak self] success in
        guard let self else { return }
        
        var e = self.createEvent()
        if success {
          e.didPurchaseProduct(with: product.productIdentifier)
        }
        else {
          e.didReceiveError(.noInternet)
        }
        self.handleEventAndCloseIfFinal(e)
      }
    }

    public func showTerms() {
      guard let url = NSURL(string: config.paywall.urls.terms) else { return }

      let safariVC = SFSafariViewController(url: url as URL)
      safariVC.delegate = self
      present(safariVC, animated: true)
    }

    public func showPolicy() {
      guard let url = NSURL(string: config.paywall.urls.policy) else { return }

      let safariVC = SFSafariViewController(url: url as URL)
      safariVC.delegate = self
      present(safariVC, animated: true)
    }

    public func restorePurchases() {
      paywall.restore { [weak self] result in
        guard let self else { return }
        
        var e = self.createEvent()
        switch result {
        case .products(let ids):
          ids.forEach { e.didRestoreProduct(with: $0) }
        case .error, .noProducts:
          e.didReceiveError(.restorationFailed)
          self.showErrorAlert(.restorationFailed)
        }
        self.handleEventAndCloseIfFinal(e)
      }
    }

  }
}

// MARK: - SFSafariViewControllerDelegate

extension Paywall.ViewController: SFSafariViewControllerDelegate {

  public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
    controller.dismiss(animated: true)
  }

}

// MARK: - Private

private extension Paywall.ViewController {

  // TODO: add more error messages?
  @MainActor
  func showErrorAlert(_ error: Paywall.Error) {
    switch error {
    case .noInternet where UIService.shared?.checkInternetConnection() == false :
      UIService.shared?.showAlert(title: L10n.NoInternet.title, message: L10n.NoInternet.subtitle)
    case .productNotSpecified:
      UIService.shared?.showAlert(title: "Failed", message: "Products not specified. Try later")
    case .restorationFailed:
      UIService.shared?.showAlert(title: L10n.Settings.Restore.title,
                                  message: L10n.Settings.RestoreFail.subtitle)
    default:
      UIService.shared?.showAlert(title: "Oops...", message: "Something happened. Try later")
    }
  }

}
