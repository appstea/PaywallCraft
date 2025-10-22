//
//  String+Ex.swift
//  PaywallCraft
//
//  Created by Ruslan Filistovich on 13/01/2025.
//

import Foundation
import PaywallCraftResources

public extension String {
  
  /// Returns a localized version of the string.
  var localized: String {
    // Use the PaywallCraftResources bundle for localization by referencing a public type
    let bundle = Bundle(for: PaywallCraftResources.L10n.self)
    let localizedString = bundle.localizedString(forKey: self, value: nil, table: "Localizable")
    
    // If we get the key back or empty string, try English fallback
    if localizedString == self || localizedString.isEmpty {
      // Try to get English version by looking for en.lproj specifically
      if let englishPath = bundle.path(forResource: "en", ofType: "lproj"),
         let englishBundle = Bundle(path: englishPath) {
        let englishString = englishBundle.localizedString(forKey: self, value: nil, table: "Localizable")
        
        // If English succeeds, return it
        if englishString != self && !englishString.isEmpty {
          return englishString
        }
      }
    }
    
    return localizedString
  }
  
  /// Returns a localized string with formatted values.
  /// - Parameter args: List of arguments to substitute into the string.
  /// - Returns: Localized string with formatted values.
  func localized(with args: CVarArg...) -> String {
    return String(format: localized, arguments: args)
  }
}
