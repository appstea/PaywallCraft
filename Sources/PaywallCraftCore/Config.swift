//
//  Config.swift
//
//  Created by dDomovoj on 6/23/22.
//

import Foundation
import UIKit

public struct Config {

  let paywall: Paywall
  let analytics: Analytics
  let appsflyer: Appsflyer?
  let ui: UI

  public init(paywall: Paywall,
              analytics: Analytics? = nil,
              appsflyer: Appsflyer? = nil,
              ui: UI? = nil) {
    self.paywall = paywall
    self.analytics = analytics ?? Analytics()
    self.appsflyer = appsflyer
    self.ui = ui ?? UI()
  }
}

// MARK: - UI

public extension Config {

  struct UI {
    let permissions: Permissions?
    let paywall: Paywall?
    let upsell: Upsell?

    public init(
      permissions: Permissions? = nil,
      paywall: Paywall? = nil,
      upsell: Upsell? = nil
    ) {
      self.permissions = permissions
      self.paywall = paywall
      self.upsell = upsell
    }
  }

}
