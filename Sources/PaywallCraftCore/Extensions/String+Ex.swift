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
    return NSLocalizedString(self, comment: "Localized version of the string.")
  }
  
  /// Returns a localized string with formatted values.
  /// - Parameter args: List of arguments to substitute into the string.
  /// - Returns: Localized string with formatted values.
  func localized(with args: CVarArg...) -> String {
    return String(format: localized, arguments: args)
  }
}
