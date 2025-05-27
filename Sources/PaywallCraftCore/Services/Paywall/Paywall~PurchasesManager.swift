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

// MARK: - PaywallShowData
public extension Paywall {
  struct PaywallShowData {
    public let canShowRCPaywall: Bool
    public let shouldWaitOfferingsToLoad: Bool
    
    public init(canShowRCPaywall: Bool, shouldWaitOfferingsToLoad: Bool) {
      self.canShowRCPaywall = canShowRCPaywall
      self.shouldWaitOfferingsToLoad = shouldWaitOfferingsToLoad
    }
  }
}

// MARK: - PurchasesManager
extension Paywall {
  final class PurchasesManager: NSObject {
    
    // MARK: - RCSetup
    struct RCSetup {
      let offering: String
    }
    
    // MARK: - Const
    private enum Const {
      static let requestMaxTryCount = 5
      static let retryDelay = DispatchTimeInterval.seconds(1)
      static let syncDelay = DispatchTimeInterval.seconds(1)
    }
    
    var debugPremium = false
    
    var hasProducts: Bool { !products.isEmpty }
    var isPremium: Bool {
      if isDebug { return debugPremium || premium }
      return premium
    }
    
    private var isLoadingProducts: Bool = false
    private var isLoadingCustomerInfo: Bool = false
    private var productsRequestTry = 0
    private var customerInfoTry = 0
    
    private weak var currentPaywallScreen: Paywall.ViewController?
    private let transactionsObserver = TransactionsObserver()
    
    private var offerings: Offerings?
    
    private var currentOffering: Offering?
    
    private var currentAllCardOffering: Offering?
    private var currentCardOffering: Offering?
    private var currentMapOffering: Offering?
    private var currentOnboardingOffering: Offering?
    private var currentSessionOffering: Offering?
    
    private var products: Set<StoreProduct> = [] {
      didSet { Notification.Paywall.Update.post(.products) }
    }
    
    private var productsAllCard: Set<StoreProduct> = [] {
      didSet { Notification.Paywall.Update.post(.products) }
    }
    private var productsCard: Set<StoreProduct> = [] {
      didSet { Notification.Paywall.Update.post(.products) }
    }
    private var productsMap: Set<StoreProduct> = [] {
      didSet { Notification.Paywall.Update.post(.products) }
    }
    private var productsOnboarding: Set<StoreProduct> = [] {
      didSet { Notification.Paywall.Update.post(.products) }
    }
    private var productsSession: Set<StoreProduct> = [] {
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
        .with(storeKitVersion: .storeKit1)
        .build()
      Purchases.configure(with: rcConfiguration)
      Purchases.shared.attribution.enableAdServicesAttributionTokenCollection()
      Purchases.shared.delegate = self
      SKPaymentQueue.default().add(transactionsObserver)
      syncIfNeeded()
    }
    
    // MARK: - Public
    func createEvent() -> Paywall.Event { .init(isPremium: isPremium) }
    
    // MARK: - UI
    @MainActor
    func paywallScreen(source: some IPaywallSource, screen: some IPaywallScreen, onEvents: Paywall.OnEvents? = nil) -> Paywall.ViewController {
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
    func showPaywallScreen(source: some IPaywallSource, screen: some IPaywallScreen, from presenter: UIViewController, showData: PaywallShowData, onEvents: Paywall.OnEvents? = nil) {
      if let current = currentPaywallScreen {
        if current.source == source, current.screen == screen {
          return
        }
        
        self.hideCurrentPaywallScreen(animated: true) { [weak self] in
          self?.showPaywallScreen(source: source, screen: screen, from: presenter, showData: showData, onEvents: onEvents)
        }
      }
      
//      if currentOffering == nil && showData.shouldWaitOfferingsToLoad { return }
      
      if showData.canShowRCPaywall {
        self.showRCPaywallIfPossible(showData: showData, from: presenter, source: source, onEvents: onEvents)
      } else {
        self.showOurPaywall(source: source, screen: screen, from: presenter, onEvents: onEvents)
      }
    }
    
    private func showRCPaywallIfPossible(showData: PaywallShowData, from presenter: UIViewController, source: some IPaywallSource, onEvents: Paywall.OnEvents? = nil) {
      Paywall.Service.shared?.updateAttribute(.paywall_source(source))
      if let placementOffering = offerings?.currentOffering(forPlacement: source.analytics.value.lowercased()) {
        let controller = PaywallViewController(offering: placementOffering)
        controller.delegate = self
        presenter.present(controller, animated: true)
        self.onEvents = onEvents
        if let presenter = presenter as? UIViewControllerTransitioningDelegate {
          controller.transitioningDelegate = presenter
        }
        debugPrint("[DEBUG] RCPaywall opened placementOffering")
      } else {
        let controller = PaywallViewController(offering: nil)
        controller.delegate = self
        presenter.present(controller, animated: true)
        self.onEvents = onEvents
        if let presenter = presenter as? UIViewControllerTransitioningDelegate {
          controller.transitioningDelegate = presenter
        }
        debugPrint("[DEBUG] RCPaywall opened nil")
      }
    }
    
    @MainActor
    private func showOurPaywall(source: some IPaywallSource, screen: some IPaywallScreen, from presenter: UIViewController, onEvents: Paywall.OnEvents? = nil) {
      let paywallVC = paywallScreen(source: source, screen: screen) { [weak self] in
        self?.currentPaywallScreen = nil
        onEvents?($0)
      }
      
      currentPaywallScreen = paywallVC
      paywallVC.modalPresentationStyle = .overFullScreen
      presenter.present(paywallVC, animated: true)
      
      if let presenter = presenter as? UIViewControllerTransitioningDelegate {
        paywallVC.transitioningDelegate = presenter
      }
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
        case .purchased: result = .purchased(isTrial: product.introductoryDiscount?.paymentMode == .freeTrial)
        case .restored: result = .restored(isTrial: product.introductoryDiscount?.paymentMode == .freeTrial)
        default: result = error == nil ? .unknown : .failed
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
    
//    func productsList() -> [StoreProduct] {
//      switch config.placement {
//      case .all_card:
//        Array(productsAllCard)
//      case .card:
//        Array(productsCard)
//      case .map:
//        Array(productsMap)
//      case .onboarding:
//        Array(productsOnboarding)
//      case .session:
//        Array(productsSession)
//      }
//
//    }
  }
}

// MARK: - PaywallViewControllerDelegate
extension Paywall.PurchasesManager: PaywallViewControllerDelegate {
  func paywallViewController(_ controller: PaywallViewController, didFinishPurchasingWith customerInfo: CustomerInfo) {
    handleCustomerInfo(customerInfo)
    onEvents?(.init(isPremium: premium))
    controller.dismiss(animated: true)
  }
  
  func paywallViewController(_ controller: PaywallViewController, didFinishRestoringWith customerInfo: CustomerInfo) {
    handleCustomerInfo(customerInfo)
    onEvents?(.init(isPremium: premium))
    controller.dismiss(animated: true)
  }
}

// MARK: - Private
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
//    let placementOffering = offerings.getCurrentOffering(forPlacement: "onboarding_end")
    Purchases.shared.getOfferings { offerings, error in
      
      self.offerings = offerings
      
      if let offering = offerings?.all.first(where: { $0.key == self.config.paywall.offering }) {
        self.currentOffering = offering.value
      } else {
        self.currentOffering = offerings?.current
      }
      
      if let offering = offerings?.currentOffering(forPlacement: "all_card") {
        self.currentAllCardOffering = offering
      } else {
        self.currentAllCardOffering = offerings?.current
      }
      
      if let offering = offerings?.currentOffering(forPlacement: "card") {
        self.currentCardOffering = offering
      } else {
        self.currentCardOffering = offerings?.current
      }
      
      if let offering = offerings?.currentOffering(forPlacement: "map") {
        self.currentMapOffering = offering
      } else {
        self.currentMapOffering = offerings?.current
      }
      
      if let offering = offerings?.currentOffering(forPlacement: "onboarding") {
        self.currentOnboardingOffering = offering
      } else {
        self.currentOnboardingOffering = offerings?.current
      }
      
      if let offering = offerings?.currentOffering(forPlacement: "session") {
        self.currentSessionOffering = offering
      } else {
        self.currentSessionOffering = offerings?.current
      }
      
      if let packages = self.currentOffering?.availablePackages {
        for package in packages {
          self.products.insert(package.storeProduct)
        }
      }
      
      if let packages = self.currentAllCardOffering?.availablePackages {
        for package in packages {
          self.productsAllCard.insert(package.storeProduct)
        }
      }
      
      if let packages = self.currentCardOffering?.availablePackages {
        for package in packages {
          self.productsCard.insert(package.storeProduct)
        }
      }
      
      if let packages = self.currentMapOffering?.availablePackages {
        for package in packages {
          self.productsMap.insert(package.storeProduct)
        }
      }
      
      if let packages = self.currentOnboardingOffering?.availablePackages {
        for package in packages {
          self.productsOnboarding.insert(package.storeProduct)
        }
      }
      
      if let packages = self.currentSessionOffering?.availablePackages {
        for package in packages {
          self.productsSession.insert(package.storeProduct)
        }
      }
      
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
      self.premium = false
      DispatchQueue.main.asyncAfter(deadline: .now() + Const.retryDelay) { [weak self] in
        self?.getCustomerInfo()
      }
      return
    }
    
    self.premium = info.entitlements.active.isEmpty == false
  }
  
}

// MARK: - PurchasesDelegate
extension Paywall.PurchasesManager: PurchasesDelegate {
  func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
    self.handleCustomerInfo(customerInfo)
  }
  
  func purchases(_ purchases: Purchases, readyForPromotedProduct product: StoreProduct, purchase startPurchase: @escaping StartPurchaseBlock) {
    startPurchase { [weak self] _, customInfo, _, _ in
      self?.handleCustomerInfo(customInfo)
    }
  }
}

// MARK: - SKPaymentTransactionObserver
private class TransactionsObserver: NSObject, SKPaymentTransactionObserver {
  func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) { }
  func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool { true }
}
