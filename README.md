# PaywallCraft

## Common

* Add dependency git@github.com:appstea/PaywallCraft.git to your target via SPM

## Project

* Add GoogleService-Info.plist to your project
* Add next fields to Info.plst:
- FirebaseAppDelegateProxyEnabled = NO
- branch_key = <Your branch api key> # e.g. key_live_pj3V9nLR39qPjoKPG34IFcjnCDmV0OCI
- in case of using fastlane add `use_system_scm: false` to `gym` call

## Code

* Example of integration via config:
```
import PaywallCraftCore

var PaywallCore: PaywallCraftCore.Instance { _Paywall.core }
private enum _Paywall {

  static let core = PaywallCraftCore.Instance(config: config)
  
  static let config = PaywallCraftCore.Config(
    paywall: .init(
      apiKey: "appl_PrQxhLfrujRwauAlGngBUArKhIK",
      offering: "com.appstea.proto.first",
      isDebug: isDebug,
      urls: .init(
        policy: "https://appstea.com/legal/privacy-policy/",
        terms: "https://appstea.com/legal/terms-of-use/"
      )
    ),
    analytics: .init(
      isOSLogEnabled: isDebug || isAdHoc,
      isFirebaseEnabled: true,
      isBranchEnabled: true
    ),
    ui: .init(
      permissions: .custom(),
      paywall: .custom(),
      upsell: .custom()
    )
  )

}

// MARK: - Upsell.Custom

fileprivate extension Config.UI.Upsell {

  static func custom() -> Self? {
    Self()
    // Adjusting default upsell banner
      .default { defaultUpsell in
        defaultUpsell
          // default upsell banner background
          .background { defaultUpsellBackground in
            defaultUpsellBackground
              .cornerRadius(0)
              .backgroundColor(.blue)
          }
          // default upsell banner icon 
          .icon { defaultUpsellIcon in
            defaultUpsellIcon
              .size(.value(CGSize(width: 32, height: 32)))
              .view { defaultUpsellIconView in
                defaultUpsellIconView
                  .backgroundColor(.clear)
                  .cornerRadius(16)
              }
          }
          // default upsell banner title
          .title { defaultUpsellTitle in
            defaultUpsellTitle.text(
              PaywallCraftUI.VM.Text("Ads free and premimum features")
                .font(.boldSystemFont(ofSize: 16))
                .textColor(.green)
            )
            .adjustsFontSize(.minScale(0.8))
            .numberOfLines(2)
          }
          // default upsell banner cta button
          .cta { cta in
            cta
              .height(30)
              .text { ctaText in
                ctaText
                  .string("Custom Text")
                  .textColor(.red)
                  .font(.systemFont(ofSize: 20))
              }
              .textPadding(UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 16))
              .background { ctaBackground in
                ctaBackground
                  .backgroundColor(.blue)
                  .cornerRadius(12)
              }
          }
          // default upsell banner most outer padding (currently horizontal only)
          .contentPadding(UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0))
          // default upsell banner title padding (currently horizontal only)
          .titlePadding(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10))
      }
      // upsell banner background
      .background {
        $0.backgroundColor(.red)
      }
  }

}

// MARK: - Permissions.Custom

fileprivate extension Config.UI.Permissions {

  static func custom() -> Self? {
    var result = Self()
    result.dotColor = .red
    return result
    // return nil
  }

}

// MARK: - Paywall.Custom

fileprivate extension Config.UI.Paywall {

  static func custom() -> Self? {
    var result = Self()
    result.textColor = .red
    return result
    // return nil
  }

}

```
* In case you're using only AppDelegate setup:

AppDelegate.swift
```
import UIKit
import Cascade

@main
final class AppDelegate: Cascade.AppDelegate {

  @objc
  override func targets() -> [UIApplicationDelegate] {[ PaywallCore ]}

  // ...

}
```

* In case you're using UIWindowScene setup:

AppDelegate.swift
```
import UIKit
import Cascade

@main
final class AppDelegate: Cascade.AppDelegate {

  @objc
  override func targets() -> [UIApplicationDelegate] {[ Paywall.core ]}

  override func application(_ application: UIApplication,
                            configurationForConnecting connectingSceneSession: UISceneSession,
                            options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }
  
  // ...

}

```

SceneDelegate.swift
```
import UIKit
import Cascade

final class SceneDelegate: Cascade.SceneDelegate & UIWindowSceneDelegate {

  @objc
  override func targets() -> [UISceneDelegate] {[ PaywallCore.scene ]}

  var window: UIWindow?

  override func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
                      options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = (scene as? UIWindowScene) else { return }

    window = UIWindow(windowScene: windowScene)
    // your setup ...
  }

}
```

* Upsell integration:
```
import PaywallCraftCore

class ViewController: UIViewController {

  private lazy var bannerView = PaywallCore.upsell(
    source: PaywallCraftCore.Paywall.Source.bottomUpsell,
    screen: PaywallCraftCore.Paywall.Screen.initial,
    from: self,
    onEvents: { [weak self] in print($0) }
  )

  // MARK: - Lifecycle

  override func loadView() {
    super.loadView()
    view.addSubviews(upsellView)
  }

  override func viewWillTransition(to size: CGSize,
                                   with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(alongsideTransition: { _ in
      self.view.setNeedsLayout()
      self.view.layoutIfNeeded()
    }, completion: nil)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    // layout upsell view
    // e.g. via PinLayout
    let safeArea = view.pin.safeArea
    if !PaywallCore.isPremium {
      upsellView.pin.start().end()
        .bottom(safeArea.bottom)
        .sizeToFit(.width)
    }
  }

}
```

To make paywall screens work as intended (to be shown from upsell etc) you need to assign keyWindow to SDK somewhere in code:
```
import PaywallCraftCore

PaywallCore.assignKeyWindow(window)
```

* To show Permissions screen:
```
import PaywallCraftCore

await PaywallCore.showPermissions()
```

* To show Onboarding Paywall screen:
```
import PaywallCraftCore

await PaywallCore.showOnboardingPaywall()
```

* To perform ATT check:
```
import PaywallCraftCore

await PaywallCore.checkATT()
```

* To create custom Paywall Source or Screen entitiy:
```
import PaywallCraftCore
import AnalyticsCraft
  
struct CustomSource: IPaywallSource {
  var analytics: IAnalyticsValue { "Custom Source Name".analytics() }
}

struct CustomScreen: IPaywallScreen {
  var analytics: IAnalyticsValue { "Custom Screen Name".analytics() }
}
```

* To use custom screens and/or sources it's possible to make:
```
PaywallCore.showPaywall(source: CustomSource(), screen: CustomScreen())
```
