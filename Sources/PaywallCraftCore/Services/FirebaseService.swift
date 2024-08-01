//
//  FirebaseService.swift
//
//  Created by dDomovoj on 6/14/22.
//

import UIKit

//import Firebase
//import FirebaseMessaging

final class FirebaseService: AppService {

//  private lazy var messagingListener = MessagingListener()

  // MARK: - Init
    override func test(st: String) {
        super.test(st: st)
    }
    
  private(set) static var shared: FirebaseService?
  static func prepare(using config: Config) {
      print("qwerty init")
//    if config.analytics.isFirebaseEnabled {
      shared = .init()
//    }
  }
  
  private override init() {
    super.init()
  }

//  // MARK: - Lifecycle
//
//  func application(_ application: UIApplication,
//                   didFinishLaunchingWithOptions launchOptions: LaunchOptions? = nil) -> Bool {
////    FirebaseApp.configure()
////    Messaging.messaging().delegate = messagingListener
//    return true
//  }
//
//  func application(_ application: UIApplication,
//                   didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
////    Messaging.messaging().apnsToken = deviceToken
//  }

}

// MARK: - MessagingListener

//private class MessagingListener: NSObject, MessagingDelegate {
//
//  private var paywall: Paywall.Service? { .shared }
//
//  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
//    if let fcmToken = fcmToken {
//      paywall?.updateAttribute(.fcm(fcmToken))
//    }
//    NotificationCenter.default.post(name: Foundation.Notification.Name("FCMToken"),
//                                    object: nil,
//                                    userInfo: ["token": fcmToken as Any])
//  }
//
//}
