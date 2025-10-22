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
    // Use the PaywallCraftResources bundle for localization by referencing a public marker class
    let bundle = Bundle(for: PaywallCraftResourcesBundleToken.self)
    let localizedString = bundle.localizedString(forKey: self, value: nil, table: "Localizable")
    
    // If we get the key back, it means localization failed - return empty string to hide it
    if localizedString == self {
      return ""
    }
    
    // If we get empty string, try English fallback
    if localizedString.isEmpty {
      // Try to get English version by looking for en.lproj specifically
      if let englishPath = bundle.path(forResource: "en", ofType: "lproj"),
         let englishBundle = Bundle(path: englishPath) {
        let englishString = englishBundle.localizedString(forKey: self, value: nil, table: "Localizable")
        
        // If English succeeds, return it; otherwise return empty string
        if englishString != self && !englishString.isEmpty {
          return englishString
        }
      }
      return ""
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
