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
  let att: ATT
    
  public init(paywall: Paywall,
              att: ATT,
              analytics: Analytics? = nil,
              appsflyer: Appsflyer? = nil,
              ui: UI? = nil) {
    self.paywall = paywall
    self.att = att
    self.analytics = analytics ?? Analytics()
    self.appsflyer = appsflyer
    self.ui = ui ?? UI()
  }
}

// MARK: - ATT

public extension Config {

  struct ATT {
    let fullScreen: Bool

    public init(
      fullScreen: Bool
    ) {
      self.fullScreen = fullScreen
    }
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
