//
//  Paywall~PurchasesManager.swift
//
//  Created by dDomovoj on 6/15/22.
//

import Foundation

import StoreKit
import AppTrackingTransparency
import AdSupport

import RevenueCat
import RevenueCatUI

import Stored

extension Paywall {

  final class PurchasesManager: NSObject {

    struct RCSetup {
//      let apiKey: String
      let offering: String

//      Внутри него packages:
//      $rc_monthly и
//      $rc_annual
    }

    private enum Const {
      static let requestMaxTryCount = 5
      static let retryDelay = DispatchTimeInterval.seconds(1)
      static let syncDelay = DispatchTimeInterval.seconds(1)
    }

    var debugPremium = false

    var hasProducts: Bool { !products.isEmpty }
    var isPremium: Bool {
      if isDebug {
        return debugPremium || premium
      }
      return premium
    }

    private var isLoadingProducts: Bool = false
    private var isLoadingCustomerInfo: Bool = false
    private var productsRequestTry = 0
    private var customerInfoTry = 0

    private weak var currentPaywallScreen: Paywall.ViewController?
    private let transactionsObserver = TransactionsObserver()

    private var currentOffering: Offering?

    private var products: Set<StoreProduct> = [] {
      didSet { Notification.Paywall.Update.post(.products) }
    }
      
    private var premium: Bool = false {
      didSet {
        if oldValue != premium {
          Notification.Paywall.Update.post(.status)

          Stored.isPremium = premium
        }
      }
    }

    private let config: Config
    private let isDebug: Bool
    private let rcSetup: RCSetup

    private var onEvents: Paywall.OnEvents?
      
    // MARK: - Init

    init(config: Config) {
      self.config = config
      isDebug = config.paywall.isDebug
      rcSetup = .init(offering: config.paywall.offering)
      super.init()

      Purchases.logLevel = isDebug ? .debug : .warn
      let rcConfiguration = RevenueCat.Configuration.Builder(withAPIKey: config.paywall.apiKey)
          .with(usesStoreKit2IfAvailable: false)
          .build()
      Purchases.configure(with: rcConfiguration)
      
      if #available(iOS 14.3, *) {
          Purchases.shared.attribution.enableAdServicesAttributionTokenCollection()
      }
      else {
          Purchases.automaticAppleSearchAdsAttributionCollection = true
      }
      Purchases.shared.delegate = self
      
      SKPaymentQueue.default().add(transactionsObserver)
      syncIfNeeded()
    }

    // MARK: - Public
          
    func createEvent() -> Paywall.Event { .init(isPremium: isPremium) }
    
    // MARK: - UI

    @MainActor
    func paywallScreen(source: some IPaywallSource, screen: some IPaywallScreen,
                       onEvents: Paywall.OnEvents? = nil) -> Paywall.ViewController {
      var result: Paywall.InitialVC!
      result = Paywall.InitialVC(config: config, source: source, screen: screen) { e in
        if e.isFinal {
          result.dismiss(animated: true)
        }
        onEvents?(e)
      }
      if let vm = config.ui.paywall {
        result.viewModel = vm
      }
      return result
    }

    @MainActor
    func showPaywallScreen(source: some IPaywallSource, 
                           screen: some IPaywallScreen,
                           from presenter: UIViewController,
                           customScreen: Bool,
                           onEvents: Paywall.OnEvents? = nil) {
      if let current = currentPaywallScreen {
        if current.source == source, current.screen == screen {
          return
        }

        hideCurrentPaywallScreen(animated: true) { [weak self] in
          self?.showPaywallScreen(source: source, screen: screen,
                                  from: presenter, customScreen: customScreen, onEvents: onEvents)
        }
      }

        if #available(iOS 15.0, *) {
            if currentOffering?.paywall != nil && customScreen {
                Paywall.Service.shared?.updateAttribute(.paywall_source(source))

                let controller = PaywallViewController(offering: nil)
                controller.delegate = self
                presenter.present(controller, animated: true)
                self.onEvents = onEvents
                return
            }
        }
        
      let paywallVC = paywallScreen(source: source, screen: screen) { [weak self] in
        self?.currentPaywallScreen = nil
        onEvents?($0)
      }

      currentPaywallScreen = paywallVC
      paywallVC.modalPresentationStyle = .overFullScreen
      presenter.present(paywallVC, animated: true)
    }

    func hideCurrentPaywallScreen(animated: Bool = true, completion: (() -> Void)? = nil) {
      let current = currentPaywallScreen
      currentPaywallScreen?.dismiss(animated: animated) { [weak self] in
        if current == self?.currentPaywallScreen {
          self?.currentPaywallScreen = nil
        }
        
        if let e = self?.createEvent() {
          current?.handleEventAndCloseIfFinal(e)
        }
        completion?()
      }
    }

    // MARK: - Logic

    func syncIfNeeded() {
      if !isLoadingCustomerInfo {
        customerInfoTry = 0
        getCustomerInfo()
      }

      if !isLoadingProducts {
        productsRequestTry = 0
        getProductsInfo()
      }
    }

    enum PurchaseResult: Equatable {
      case purchasing
      case purchased(isTrial: Bool)
      case restored(isTrial: Bool)
      case failed
      case deferred
      case unknown
    }
      
    func purchase(product: StoreProduct, source: some IPaywallSource, completion: ((PurchaseResult) -> Void)?) {
      Paywall.Service.shared?.updateAttribute(.paywall_source(source))

      HUD.show()
      Purchases.shared.purchase(product: product) { [weak self] transaction, customerInfo, error, _ in
        defer {
          HUD.dismiss()
        }
        guard let transaction = transaction else {
          completion?(.failed)
          return
        }

        let result: PurchaseResult
        switch transaction.sk1Transaction?.transactionState {
        case .failed: result = .failed
        case .deferred: result = .deferred
        case .purchasing: result = .purchasing
        case .purchased:
          result = .purchased(isTrial: product.introductoryDiscount?.paymentMode == .freeTrial)
        case .restored:
          result = .restored(isTrial: product.introductoryDiscount?.paymentMode == .freeTrial)
        default:
          result = error == nil ? .unknown : .failed
        }

        if let self = self {
          let hasActiveEntitlement = customerInfo?.entitlements.active.isEmpty == false
          self.premium = hasActiveEntitlement
          
          if !hasActiveEntitlement {
            self.schedulePurchaseSync()
          }
        }
        completion?(result)
      }
    }

    func restore(block: ((RestoreResponseType) -> Void)?) {
      HUD.show()
      Purchases.shared.restorePurchases { [weak self] customInfo, error in
        defer { HUD.dismiss() }
        guard let self = self else { return }

        guard error == nil else {
          block?(.error)
          return
        }

        if customInfo?.entitlements.active.isEmpty == false {
          self.premium = true
          
          let restored = self.products
            .filter { customInfo?.entitlements[$0.productIdentifier]?.isActive == true }
            .map(\.productIdentifier)
          block?(.products(Set(restored)))
        }
        else {
          block?(.noProducts)
        }
      }
    }

    func productsList() -> [StoreProduct] {
      Array(products)
    }
  }
}

// MARK: - Private

extension Paywall.PurchasesManager: PaywallViewControllerDelegate {
  
  @available(iOS 15.0, *)
  func paywallViewController(_ controller: PaywallViewController,
                             didFinishPurchasingWith customerInfo: CustomerInfo) {
      handleCustomerInfo(customerInfo)
      onEvents?(.init(isPremium: premium))
      controller.dismiss(animated: true)
  }
  
  @available(iOS 15.0, *)
  func paywallViewController(_ controller: PaywallViewController,
                             didFinishRestoringWith customerInfo: CustomerInfo) {
      handleCustomerInfo(customerInfo)
      onEvents?(.init(isPremium: premium))
      controller.dismiss(animated: true)
  }
}

private extension Paywall.PurchasesManager {

  func getCustomerInfo() {
    customerInfoTry += 1
    guard customerInfoTry <= Const.requestMaxTryCount else {
      isLoadingCustomerInfo = false
      return
    }

    isLoadingCustomerInfo = true
    Purchases.shared.getCustomerInfo { [weak self] customerInfo, _ in
      self?.handleCustomerInfo(customerInfo)
    }
  }

  func getProductsInfo() {
    productsRequestTry += 1
    guard productsRequestTry <= Const.requestMaxTryCount else {
      isLoadingProducts = false
      return
    }

    isLoadingProducts = true
    Purchases.shared.getOfferings { [weak self] offerings, _ in
      guard let self = self else { return }

      // TODO: Add support for additional offerrings
//      if let packages = offerings?.offering(identifier: self.rcSetup.offering)?.availablePackages {
//        for package in packages {
//          self.products.insert(package.storeProduct)
//        }
//      }
              
        if let offering = offerings?.all.first(where: { $0.key == self.config.paywall.offering }) {
            self.currentOffering = offering.value
        } else {
            self.currentOffering = offerings?.current
        }
        
      if let packages = self.currentOffering?.availablePackages {
        for package in packages {
          self.products.insert(package.storeProduct)
        }
      }
      
      debugPrint("[DEBUG] Products: \(self.products)")
      self.isLoadingProducts = false
      Notification.Paywall.Update.post(.products)
    }
  }

  func schedulePurchaseSync() {
    DispatchQueue.main.asyncAfter(deadline: .now() + Const.syncDelay) { [weak self] in
      self?.syncIfNeeded()
    }
  }

  func handleCustomerInfo(_ info: CustomerInfo?) {
    guard let info = info else {
      premium = false
      DispatchQueue.main.asyncAfter(deadline: .now() + Const.retryDelay) { [weak self] in
        self?.getCustomerInfo()
      }
      return
    }

    premium = info.entitlements.active.isEmpty == false
  }

}

// MARK: - PurchasesDelegate

extension Paywall.PurchasesManager: PurchasesDelegate {

  func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
    handleCustomerInfo(customerInfo)
  }

  func purchases(_ purchases: Purchases,
                 readyForPromotedProduct product: StoreProduct,
                 purchase startPurchase: @escaping StartPurchaseBlock) {
    startPurchase { [weak self] _, customInfo, _, _ in
      self?.handleCustomerInfo(customInfo)
    }
  }

}

// MARK: - TransactionsObserver

private class TransactionsObserver: NSObject, SKPaymentTransactionObserver {

  func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) { }

  func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
    true
  }

}
