//
//  _RC.StoreProduct~Extensions.swift
//
//  Created by dDomovoj on 6/16/22.
//

import Foundation

import StoreKit
import RevenueCat

import Utils
import PaywallCraftResources

extension StoreProduct {
  /// $4.99
  func localizedPrice() -> String {
    if #available(iOS 16, *) {
      let locale = priceFormatter?.locale ?? .autoupdatingCurrent
      return sk2Product?.localizedPrice(locale) ?? ""
    } else {
      return sk1Product?.localizedPrice() ?? ""
    }
  }
  
  /// $3.33 for $9.99 per quartal
  func localizedUnitPrice() -> String {
    if #available(iOS 16, *) {
      let locale = priceFormatter?.locale ?? .autoupdatingCurrent
      return sk2Product?.localizedUnitPrice(locale) ?? ""
    } else {
      return sk1Product?.localizedUnitPrice() ?? ""
    }
  }
  
  /// $4.99 per month
  func localizedPricePerPeriod() -> String {
    if #available(iOS 16, *) {
      let locale = priceFormatter?.locale ?? .autoupdatingCurrent
      return sk2Product?.localizedPricePerPeriod(locale) ?? ""
    } else {
      return sk1Product?.localizedPricePerPeriod() ?? ""
    }
  }
  
  /// $3.33 per month for 9.99$ per quartal
  func localizedPricePerUnit() -> String {
    if #available(iOS 16, *) {
      let locale = priceFormatter?.locale ?? .autoupdatingCurrent
      return sk2Product?.localizedPricePerUnit(locale) ?? ""
    } else {
      return sk1Product?.localizedPricePerUnit() ?? ""
    }
  }
  
  /// $4.99/month
  func localizedPriceSlashPeriod() -> String {
    if #available(iOS 16, *) {
      let locale = priceFormatter?.locale ?? .autoupdatingCurrent
      return sk2Product?.localizedPriceSlashPeriod(locale) ?? ""
    } else {
      return sk1Product?.localizedPriceSlashPeriod() ?? ""
    }
  }
  
  /// $3.33/month for 9.99$ per quartal
  func localizedPriceSlashPeriodUnit() -> String {
    if #available(iOS 16, *) {
      let locale = priceFormatter?.locale ?? .autoupdatingCurrent
      return sk2Product?.localizedPriceSlashPeriodUnit(locale) ?? ""
    } else {
      return sk1Product?.localizedPriceSlashPeriodUnit() ?? ""
    }
  }
    
  /// $0.99/month for 11.99$ per year
  func localizedMonthlyPriceSlashMonth() -> String {
    guard let pricePerMonth = pricePerMonth else { return "" }
        
    var localizedPrice = ""
    var localizedPeriod = ""
    if #available(iOS 16, *) {
        localizedPrice = sk2Product?.numberFormatter.string(from: pricePerMonth) ?? ""
        localizedPeriod = sk2Product?.localizedPeriod(for: .month) ?? ""
    } else {
        localizedPrice = sk1Product?.numberFormatter.string(from: pricePerMonth) ?? ""
        localizedPeriod = sk1Product?.localizedPeriod(for: .month) ?? ""
    }
        
    let result = L10n.Paywall.priceSlashPeriod(localizedPrice, localizedPeriod)
    return result
  }
  
  func localizedPeriodUnit() -> String {
    if #available(iOS 16, *) {
      return sk2Product?.localizedPeriodUnit() ?? ""
    } else {
      return sk1Product?.localizedPeriodUnit() ?? ""
    }
  }
  
  func localizedPeriod() -> String {
    if #available(iOS 16, *) {
      return sk2Product?.localizedPeriod() ?? ""
    } else {
      return sk1Product?.localizedPeriod() ?? ""
    }
  }
  
  func trialCount() -> Int {
    if #available(iOS 16, *) {
      return sk2Product?.trialCount() ?? 0
    } else {
      return sk1Product?.trialCount() ?? 0
    }
  }
}

@available(iOS 15.0, *)
fileprivate extension SK2Product {
  private static let numberFormatter = NumberFormatter {
    $0.numberStyle = .currency
    $0.formatterBehavior = .behavior10_4
  }
    
  /// $4.99
  func localizedPrice(_ priceLocale: Locale) -> String {
    return numberFormatter.string(from: price as NSDecimalNumber) ?? ""
  }
  
  /// $3.33 for $9.99 per quartal
  func localizedUnitPrice(_ priceLocale: Locale) -> String {
    let price = price as NSDecimalNumber
    let unitPrice = price.dividing(by: .init(integerLiteral: subscription?.subscriptionPeriod.value ?? 1))
    return numberFormatter.string(from: unitPrice) ?? ""
  }
  
  /// $4.99 per month
  func localizedPricePerPeriod(_ priceLocale: Locale) -> String {
    L10n.Paywall.pricePerPeriod(localizedPrice(priceLocale), localizedPeriod())
  }
  
  /// $3.33 per month for 9.99$ per quartal
  func localizedPricePerUnit(_ priceLocale: Locale) -> String {
    L10n.Paywall.pricePerPeriod(localizedUnitPrice(priceLocale), localizedPeriodUnit())
  }
  
  /// $4.99/month
  func localizedPriceSlashPeriod(_ priceLocale: Locale) -> String {
    L10n.Paywall.priceSlashPeriod(localizedPrice(priceLocale), localizedPeriod())
  }
  
  /// $3.33/month for 9.99$ per quartal
  func localizedPriceSlashPeriodUnit(_ priceLocale: Locale) -> String {
    L10n.Paywall.priceSlashPeriod(localizedUnitPrice(priceLocale), localizedPeriodUnit())
  }
  
  func localizedPeriodUnit() -> String {
    guard let period = subscription?.subscriptionPeriod else { return ""}
    return localizedPeriod(for: period.unit)
  }

    // MARK: - Utils

  func localizedPeriod(for unit: Product.SubscriptionPeriod.Unit) -> String {
    typealias L10n = PaywallCraftResources.L10n.Paywall.Period
    switch unit {
    case .day: return L10n.day
    case .week: return L10n.week
    case .month: return L10n.month
    case .year: return L10n.year
    @unknown default: return ""
    }
  }
  
  func localizedPeriod() -> String {
    guard let subscriptionPeriod = subscription?.subscriptionPeriod else { return "" }
    switch subscriptionPeriod.unit {
    case .day:
      if subscriptionPeriod.value == 7 {
        return L10n.week
      }
      return L10n.day
    case .week: return L10n.week
    case .month:
      if subscriptionPeriod.value == 3 {
        return L10n.quartal
      }
      return L10n.month
    case .year: return L10n.year
    @unknown default: return ""
    }
  }
  
  func trialCount() -> Int {
    if subscription?.introductoryOffer?.period.value == 1 {
      return 7
    } else {
      return subscription?.introductoryOffer?.period.value ?? 0
    }
  }
}


fileprivate extension SKProduct {
    
    private static let numberFormatter = NumberFormatter {
      $0.numberStyle = .currency
      $0.formatterBehavior = .behavior10_4
    }

    /// $4.99
    func localizedPrice() -> String {
        return numberFormatter.string(from: price) ?? ""
    }

    /// $3.33 for $9.99 per quartal
    func localizedUnitPrice() -> String {
        let unitPrice = price.dividing(by: .init(integerLiteral: subscriptionPeriod?.numberOfUnits ?? 1))
        return numberFormatter.string(from: unitPrice) ?? ""
    }

    /// $4.99 per month
    func localizedPricePerPeriod() -> String {
        L10n.Paywall.pricePerPeriod(localizedPrice(), localizedPeriod())
    }

    /// $3.33 per month for 9.99$ per quartal
    func localizedPricePerUnit() -> String {
        L10n.Paywall.pricePerPeriod(localizedUnitPrice(), localizedPeriodUnit())
    }

    /// $4.99/month
    func localizedPriceSlashPeriod() -> String {
        L10n.Paywall.priceSlashPeriod(localizedPrice(), localizedPeriod())
    }

    /// $3.33/month for 9.99$ per quartal
    func localizedPriceSlashPeriodUnit() -> String {
        L10n.Paywall.priceSlashPeriod(localizedUnitPrice(), localizedPeriodUnit())
    }

    func localizedPeriodUnit() -> String {
      guard let period = subscriptionPeriod else { return ""}
      return localizedPeriod(for: period.unit)
    }

    // MARK: - Utils

    func localizedPeriod(for unit: SKProduct.PeriodUnit) -> String {
      typealias L10n = PaywallCraftResources.L10n.Paywall.Period
      switch unit {
      case .day: return L10n.day
      case .week: return L10n.week
      case .month: return L10n.month
      case .year: return L10n.year
      @unknown default: return ""
      }
    }

    func localizedPeriod() -> String {
        subscriptionPeriod?.map {
            switch $0.unit {
            case .day:
                if $0.numberOfUnits == 7 {
                    return L10n.week
                }
                return L10n.day
            case .week: return L10n.week
            case .month:
                if $0.numberOfUnits == 3 {
                    return L10n.quartal
                }
                return L10n.month
            case .year: return L10n.year
            @unknown default: return ""
            }
        } ?? ""
    }

    func trialCount() -> Int {
        if introductoryPrice?.subscriptionPeriod.numberOfUnits == 1 {
            return 7
        }
        else {
            return introductoryPrice?.subscriptionPeriod.numberOfUnits ?? 0
        }
    }
}
