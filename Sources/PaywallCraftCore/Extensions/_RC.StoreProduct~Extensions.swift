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

fileprivate extension SK2Product {
  /// $4.99
  func localizedPrice(_ priceLocale: Locale) -> String {
    let numberFormatter = NumberFormatter.cached(format: .currency, locale: priceLocale)
    numberFormatter.formatterBehavior = .behavior10_4
    return numberFormatter.string(from: price as NSDecimalNumber) ?? ""
  }
  
  /// $3.33 for $9.99 per quartal
  func localizedUnitPrice(_ priceLocale: Locale) -> String {
    let price = price as NSDecimalNumber
    let unitPrice = price.dividing(by: .init(integerLiteral: subscription?.subscriptionPeriod.value ?? 1))
    let numberFormatter = NumberFormatter.cached(format: .currency, locale: priceLocale)
    numberFormatter.formatterBehavior = .behavior10_4
    return numberFormatter.string(from: unitPrice) ?? ""
  }
  
  /// $4.99 per month
  func localizedPricePerPeriod(_ priceLocale: Locale) -> String {
    L10n.Subs.pricePerPeriod(localizedPrice(priceLocale), localizedPeriod())
  }
  
  /// $3.33 per month for 9.99$ per quartal
  func localizedPricePerUnit(_ priceLocale: Locale) -> String {
    L10n.Subs.pricePerPeriod(localizedUnitPrice(priceLocale), localizedPeriodUnit())
  }
  
  /// $4.99/month
  func localizedPriceSlashPeriod(_ priceLocale: Locale) -> String {
    L10n.Subs.priceSlashPeriod(localizedPrice(priceLocale), localizedPeriod())
  }
  
  /// $3.33/month for 9.99$ per quartal
  func localizedPriceSlashPeriodUnit(_ priceLocale: Locale) -> String {
    L10n.Subs.priceSlashPeriod(localizedUnitPrice(priceLocale), localizedPeriodUnit())
  }
  
  func localizedPeriodUnit() -> String {
    guard let subscriptionPeriod = subscription?.subscriptionPeriod else { return "" }
    switch subscriptionPeriod.unit {
    case .day: return L10n.Subs.Period.day
    case .week: return L10n.Subs.Period.week
    case .month: return L10n.Subs.Period.month
    case .year: return L10n.Subs.Period.year
    @unknown default: return ""
    }
  }
  
  func localizedPeriod() -> String {
    guard let subscriptionPeriod = subscription?.subscriptionPeriod else { return "" }
    switch subscriptionPeriod.unit {
    case .day:
      if subscriptionPeriod.value == 7 {
        return L10n.Subs.Period.week
      }
      return L10n.Subs.Period.day
    case .week: return L10n.Subs.Period.week
    case .month:
      if subscriptionPeriod.value == 3 {
        return L10n.Subs.Period.quartal
      }
      return L10n.Subs.Period.month
    case .year: return L10n.Subs.Period.year
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

    /// $4.99
    func localizedPrice() -> String {
        let numberFormatter = NumberFormatter.cached(format: .currency, locale: priceLocale)
        numberFormatter.formatterBehavior = .behavior10_4
        return numberFormatter.string(from: price) ?? ""
    }

    /// $3.33 for $9.99 per quartal
    func localizedUnitPrice() -> String {
        let unitPrice = price.dividing(by: .init(integerLiteral: subscriptionPeriod?.numberOfUnits ?? 1))
        let numberFormatter = NumberFormatter.cached(format: .currency, locale: priceLocale)
        numberFormatter.formatterBehavior = .behavior10_4
        return numberFormatter.string(from: unitPrice) ?? ""
    }

    /// $4.99 per month
    func localizedPricePerPeriod() -> String {
        L10n.Subs.pricePerPeriod(localizedPrice(), localizedPeriod())
    }

    /// $3.33 per month for 9.99$ per quartal
    func localizedPricePerUnit() -> String {
        L10n.Subs.pricePerPeriod(localizedUnitPrice(), localizedPeriodUnit())
    }

    /// $4.99/month
    func localizedPriceSlashPeriod() -> String {
        L10n.Subs.priceSlashPeriod(localizedPrice(), localizedPeriod())
    }

    /// $3.33/month for 9.99$ per quartal
    func localizedPriceSlashPeriodUnit() -> String {
        L10n.Subs.priceSlashPeriod(localizedUnitPrice(), localizedPeriodUnit())
    }

    func localizedPeriodUnit() -> String {
        subscriptionPeriod?.map {
            switch $0.unit {
            case .day: return L10n.Subs.Period.day
            case .week: return L10n.Subs.Period.week
            case .month: return L10n.Subs.Period.month
            case .year: return L10n.Subs.Period.year
            @unknown default: return ""
            }
        } ?? ""
    }

    func localizedPeriod() -> String {
        subscriptionPeriod?.map {
            switch $0.unit {
            case .day:
                if $0.numberOfUnits == 7 {
                    return L10n.Subs.Period.week
                }
                return L10n.Subs.Period.day
            case .week: return L10n.Subs.Period.week
            case .month:
                if $0.numberOfUnits == 3 {
                    return L10n.Subs.Period.quartal
                }
                return L10n.Subs.Period.month
            case .year: return L10n.Subs.Period.year
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
