//
//  AppsflyerService.swift
//
//  Created by dDomovoj on 6/14/22.
//

import UIKit
import AppsFlyerLib

public extension Config {
    struct Appsflyer {
        let apiKey: String
        let appID: String
        
        public init(apiKey: String, appID: String) {
            self.apiKey = apiKey
            self.appID = appID
        }
    }
}

final class AppsflyerService: AppService, AppsFlyerLibDelegate {
    
    private (set) static var shared: AppsflyerService?
    static func prepare(using config: Config) {
        if let config = config.appsflyer {
            shared = .init(apiKey: config.apiKey, appID: config.appID)
        }
    }
    
    private init(apiKey: String, appID: String) {
        super.init()
        AppsFlyerLib.shared().appsFlyerDevKey = apiKey
        AppsFlyerLib.shared().appleAppID = appID
        AppsFlyerLib.shared().delegate = self
    }
    
    private var paywall: Paywall.Service? { .shared }
    
    // MARK: - Lifecycle
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        AppsFlyerLib.shared().start()
        paywall?.updateAttribute(.appsFlyer(.id(AppsFlyerLib.shared().getAppsFlyerUID())))
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        AppsFlyerLib.shared().start()
        paywall?.updateAttribute(.appsFlyer(.id(AppsFlyerLib.shared().getAppsFlyerUID())))
    }
    
    func onConversionDataSuccess(_ conversionInfo: [AnyHashable : Any]) {
        if let status = conversionInfo["af_status"] as? String {
            if (status == "Non-organic") {
                if let mediaSource = conversionInfo["media_source"] as? String {
                    paywall?.updateAttribute(.appsFlyer(.mediaSource(mediaSource)))
                }
                if let campaign = conversionInfo["campaign"] as? String {
                    paywall?.updateAttribute(.appsFlyer(.campaign(campaign)))
                }
                if let creative = conversionInfo["af_adset_id"] as? String {
                    paywall?.updateAttribute(.appsFlyer(.creative(creative)))
                }
                if let ad = conversionInfo["af_ad"] as? String {
                    paywall?.updateAttribute(.appsFlyer(.ad(ad)))
                }
                if let adGroup = conversionInfo["af_adset"] as? String {
                    paywall?.updateAttribute(.appsFlyer(.adGroup(adGroup)))
                }
                if let keyword = conversionInfo["af_keywords"] as? String {
                    paywall?.updateAttribute(.appsFlyer(.keyword(keyword)))
                }
            }
        }
    }
    
    func onConversionDataFail(_ error: Error) { }
}
