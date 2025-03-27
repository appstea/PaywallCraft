//
//  PermissionService.swift
//
//  Created by dDomovoj on 05/11/2022.
//

import Foundation

import PermissionsKit
import NotificationPermission
import PhotoLibraryPermission
import LocationPermission
import MotionPermission
import CoreLocation

enum PermissionService {
  
  typealias Permission = Permissions.ViewModel.Permission.PermissionType
  typealias Status = Permissions.ViewModel.Permission.Status
  
}

// MARK: - Request Permissions

extension PermissionService {
  
  struct Requester: AsyncSequence, AsyncIteratorProtocol {
    
    typealias AsyncIterator = Self
    typealias Element = (Permission, Status)
    
    private var permissions: [Permission]
    init(permissions: [Permission]) {
      self.permissions = permissions
    }
    
    func makeAsyncIterator() -> AsyncIterator { self }
    mutating func next() async -> Element? {
      guard !Task.isCancelled,
            let next = permissions.first
      else { return nil }
      
      let status = await requestPermission(for: next)
      self.permissions = Array(permissions.dropFirst())
      return (next, status)
    }
    
    private func requestPermission(for permission: Permission) async -> Status {
      await withCheckedContinuation { c in
        DispatchQueue.main.async {
          let type = permission
          let permission: PermissionsKit.Permission
          
          switch type {
          case .locationAlways, .locationWhenInUse:
            let locationPermission = PermissionsKit.Permission.location(access: .always)
            locationPermission.request {
              let status = CLLocationManager().authorizationStatus
              let domainStatus: Status = (status == .authorizedAlways || status == .authorizedWhenInUse) ? .authorized : .denied
              debugPrint("[DEBUG] requestPermission location")
              c.resume(returning: domainStatus)
            }
          case .notifications:
            permission = PermissionsKit.Permission.notification()
            permission.request {
              debugPrint("[DEBUG] requestPermission notifications")
              c.resume(returning: permission.status.domain)
            }
          case .photos:
            permission = PhotoLibraryPermission()
            permission.request {
              debugPrint("[DEBUG] requestPermission photos")
              c.resume(returning: permission.status.domain)
            }
          case .motion:
            permission = MotionPermission()
            permission.request {
              debugPrint("[DEBUG] requestPermission motion")
              c.resume(returning: permission.status.domain)
            }
          }
        }
      }
    }
  }
}

// MARK: - Read Permissions

extension PermissionService {
  
  struct Fetcher: AsyncSequence, AsyncIteratorProtocol {
    
    typealias AsyncIterator = Self
    typealias Element = (Permission, Status)
    
    private var permissions: [Permission]
    init(permissions: [Permission]) {
      self.permissions = permissions
    }
    
    func makeAsyncIterator() -> AsyncIterator { self }
    mutating func next() async -> Element? {
      guard !Task.isCancelled,
            let next = permissions.first
      else { return nil }
      
      let success = await fetchPermission(for: next)
      self.permissions = Array(permissions.dropFirst())
      return (next, success)
    }
    
    private func fetchPermission(for permission: Permission) async -> Status {
      let type = permission
      let permission: PermissionsKit.Permission
      switch type {
      case .locationAlways: permission = PermissionsKit.Permission.location(access: .always)
      case .locationWhenInUse: permission = PermissionsKit.Permission.location(access: .whenInUse)
      case .notifications: permission = PermissionsKit.Permission.notification()
      case .motion: permission = MotionPermission()
      case .photos: permission = PhotoLibraryPermission()
      }
      return permission.status.domain
    }
    
  }
}

// MARK: - PermissionsKit mapping

fileprivate extension PermissionsKit.Permission.Status {
  
  var domain: PermissionService.Status {
    switch self {
    case .authorized: return .authorized
    case .notDetermined, .notSupported: return .notDetermined
    case .denied: return .denied
    }
  }
}
