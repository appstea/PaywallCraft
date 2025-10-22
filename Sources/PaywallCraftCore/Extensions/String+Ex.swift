//
//  String+Ex.swift
//  PaywallCraft
//
//  Created by Ruslan Filistovich on 13/01/2025.
//

import Foundation

public extension String {
  
  /// Returns a localized version of the string.
  var localized: String {
    // Use the PaywallCraftResources module bundle for localization
    guard let bundle = Bundle(identifier: "PaywallCraft.PaywallCraftResources") else {
      // Fallback to main bundle if module bundle not found
      return NSLocalizedString(self, comment: "Localized version of the string.")
    }
    return bundle.localizedString(forKey: self, value: nil, table: "Localizable")
  }
  
  /// Returns a localized string with formatted values.
  /// - Parameter args: List of arguments to substitute into the string.
  /// - Returns: Localized string with formatted values.
  func localized(with args: CVarArg...) -> String {
    return String(format: localized, arguments: args)
  }
}
