//
//  Permissions~VC.swift
//
//  Created by dDomovoj on 6/9/22.
//

import UIKit

import SwiftyAttributes
import PinLayout

import StackCraft

import Utils
import Stored
import UIBase
import UICommon
import PaywallCraftUI
import PaywallCraftResources

extension Stored {

  @StorageKey("paywall.didPassPrepermission", defaultValue: false)
  fileprivate(set) static var didPassPrepermission: Bool

}

public extension Config.UI {

  typealias Permissions = PaywallCraftCore.Permissions.ViewModel

}


public enum Permissions {}

extension Permissions {

  public struct ViewModel {
    public var bgColors = [
      Color.Onboarding.background.color.withAlphaComponent(0),
      Color.Onboarding.background.color.withAlphaComponent(0),
    ]
    
    public var image = VM.Image(Asset.Permissions.image.image)
      .size(.computed({ img -> CGSize in
        let intent = img.ctx.uiIntent
        if img.ctx.isPad && img.ctx.isLandscape {
          return CGSize(width: 248.ui(intent), height: 223.ui(intent))
        }
        else {
          return CGSize(width: 310.ui(intent), height: 279.ui(intent))
        }
      }))
    
    public var textColor = Color.Main.text.color
    public var ctaTextColor = UIColor.white
    public var ctaBgColor = Color.Onboarding.continue.color

    public var title = L10n.Permissions.title
    public var subtitle = L10n.Permissions.subtitle
    
    public struct Permission: Equatable {
      public enum PermissionType: Equatable {
        case notifications
        case locationAlways
        case locationWhenInUse
        case photos
        case motion
          
//        var isAvailable: Bool {
//          guard isCatalyst || isMacDesignedForPad
//          else { return true }
//
//          switch self {
//          case .motion: return false
//          default: return true
//          }
//        }
      }
      
      public enum Status: Equatable {
        case authorized
        case denied
        case notDetermined
      }
      public var type: PermissionType
      public var icon: UIImage
      public var title: String
      public var description: String
      public var color: UIColor
      public var selectionColor: UIColor
      
    }
    public var permissions: [Permission] = [
      Permission.Defaults.notifications,
      Permission.Defaults.locationAlways,
      Permission.Defaults.photos,
      Permission.Defaults.motion,
    ]
    fileprivate var resolvedPermissions: [Permission] {
      permissions
        .filter { $0.type != .motion }
        .sorted { lhs, rhs in
          if lhs.type.isAny(of: .locationAlways, .locationWhenInUse) { return false }
          if rhs.type.isAny(of: .locationAlways, .locationWhenInUse) { return true }
          return false
        }
    }
    public var cta = L10n.Permissions.Button.continue
    
    fileprivate var allowedPermissions: Set<Permissions.ViewModel.Permission.PermissionType> = []

    public init() {}

    fileprivate func apply(to view: ViewController) {
      guard Thread.isMainThread else {
        DispatchQueue.main.async {
          self.apply(to: view)
        }
        return
      }
      
      view.bgView.colors = bgColors
      view.imageView.image = image.uiImage

      view.titleLabel.text = title
      view.titleLabel.textColor = textColor

      view.subtitleLabel.text = subtitle
      view.subtitleLabel.textColor = textColor

      resolvedPermissions.enumerated().forEach { idx, feature in
        let label = view.iconLabel(idx)
        let text = feature.title
          .withFont(DynamicFont.regular(of: isPad ? 24 : 16)
            .maxSize(to: isPad ? 40 : 28)
            .asFont())
          .withTextColor(Color.Main.text.color)
          .withParagraphStyle(NSMutableParagraphStyle {
            $0.lineSpacing = 5
            $0.alignment = isRTL ? .right : .left
          })
        
        label.apply(data: .init(
          icon: feature.icon,
          color: feature.color,
          selectionColor: allowedPermissions.contains(feature.type) ? feature.selectionColor : .clear,
          text: text
        ))
      }

      view.ctaButton.setTitle(cta, for: .normal)
      view.ctaButton.setTitleColor(ctaTextColor, for: .normal)
      view.ctaButton.backgroundColor = ctaBgColor

      view.view.setNeedsLayout()
    }
  }

  final class ViewController: UIBase.ViewController {

    private enum Const {
      static var contentWidth: CGFloat { (isPad && isLandscape) ? 0.6 : 0.8 }
    }

    var viewModel = ViewModel() {
      didSet { viewModel.apply(to: self) }
    }

    private var continueTask: Task<Void, Never>?
    private var passContinuation: CheckedContinuation<Void, Never>?

    override public var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // MARK: UI

    fileprivate let bgView = UICommon.GradientView {
      $0.direction = .down
    }

    fileprivate let stackView = VStackView {
      $0.backgroundColor = .clear
    }

    fileprivate let imageView = UIBase.ImageView {
      $0.contentMode = .scaleAspectFit
    }
    fileprivate let titleLabel = UIBase.Label {
      $0.setDynamicFont(font: .systemFont(ofSize: isPad ? 30 : 20, weight: .medium),
                        maximumPointSize: isPad ? 60 : 40)
      $0.textAlignment = isRTL ? .right : .center
      $0.numberOfLines = 0
      $0.adjustsFontSizeToFitWidth = true
      $0.minimumScaleFactor = 0.8
    }
    fileprivate let subtitleLabel = UIBase.Label {
      $0.setDynamicFont(font: .systemFont(ofSize: isPad ? 24 : 16),
                        maximumPointSize: isPad ? 48 : 32)
      $0.textAlignment = isRTL ? .right : .center
      $0.numberOfLines = 0
      $0.adjustsFontSizeToFitWidth = true
      $0.minimumScaleFactor = 0.8
    }
    private var iconLabelsPool = [Int: IconLabel]()
    fileprivate func iconLabel(_ idx: Int) -> IconLabel {
      let result = iconLabelsPool[idx] ?? IconLabel()
      iconLabelsPool[idx] = result
      return result
    }

    fileprivate let ctaButton = UIBase.Button {
      $0.layer.cornerRadius = 12
      $0.titleLabel?.font = .systemFont(ofSize: isPad ? 30 : 20, weight: .medium)
    }.asAccessibilityElement()

    // MARK: - Lifecycle

    override func loadView() {
      super.loadView()
      view.backgroundColor = Color.Main.back.color
      view.addSubviews(bgView, stackView)
    }

    override func viewDidLoad() {
      super.viewDidLoad()
      viewModel.apply(to: self)
      checkAuthorizedFeaturesPermissions()
      
      view.setNeedsLayout()
      ctaButton.addAction { [weak self] _ in self?.onContinue() }
      //        reload(for: onboarding)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
      super.traitCollectionDidChange(previousTraitCollection)
      
      viewModel.apply(to: self)
      view.setNeedsLayout()
    }

    override func viewDidLayoutSubviews() {
      super.viewDidLayoutSubviews()

      let safeArea = view.pin.safeArea
      let contentWidth = view.bounds.width * Const.contentWidth

      if isPad && isPortrait {
        bgView.pin.top().horizontally().height(35%)
      }
      else {
        bgView.pin.top().horizontally().height(280.ui(.paywall) + safeArea.top)
      }
      stackView.pin.hCenter().width(contentWidth).vertically(safeArea)
      if viewModel.image.containerSize != stackView.bounds.size {
        viewModel.image.containerSize = stackView.bounds.size
      }
      
      reloadUI()
    }

    // MARK: - Public

    func result() async {
      await withCheckedContinuation { [weak self] c in
        self?.passContinuation = c
      }
    }

  }
}

// MARK: - Private

fileprivate extension Permissions.ViewController {

  func reloadUI() {
    let w = stackView.bounds.width
    let ctaFitWidth = isPad
    ? min(w - 20.ui(.paywall), 400.ui(.paywall))
    : 285.ui(.paywall)
    
    stackView.reload {
      if (isPad && isPortrait) {
        20.fixed
        100.floating
      }
      else {
        25.floating
      }
      imageView.vComponent
        .size(viewModel.image.calculateSize())
        .alignment(.center)
      isPad ? 30.floating : 4.floating
      titleLabel.vComponent.maxHeight(40.ui(.paywall))
      isPad ? 20.floating : 8.floating
      subtitleLabel.vComponent.maxHeight(30.ui(.paywall))
      isPad ? 16.floating : 20.floating

      iconLabels(widthToFit: ctaFitWidth)
      
      isPad ? 60.floating : 30.floating
      ctaButton.vComponent
        .size(CGSize(width: ctaFitWidth, height: isPad ? 70 : 50))
        .alignment(.center)
      30.floating
      30.fixed
    }
    
    func iconLabels(widthToFit: CGFloat) -> [VStackViewItemConvertible] {
      iconLabelsPool.keys.sorted().enumerated().flatMap { idx, key -> [VStackViewItemConvertible] in
        let label = iconLabel(key)
        let isLast = idx == iconLabelsPool.count - 1
        let component = label.vComponent
          .width(.fixed(widthToFit))
          .height(.floating(48.ui(.paywall)))
          .alignment(.center)
        if isLast {
          return [component]
        }
        
        return [
          component,
          isPad ? 16.floating : 8.floating
        ]
      }
    }
    
  }
}

// MARK: - Actions

private extension Permissions.ViewController {

  func onContinue() {
    let generator = UIImpactFeedbackGenerator(style: .light)
    generator.impactOccurred()
    
    continueTask?.cancel()
    continueTask = Task {
      await requestPermissions()
      Stored.didPassPrepermission = true
      try? await Task.sleep(nanoseconds: NSEC_PER_SEC * 1)
      passContinuation?.resume(returning: Void())
      passContinuation = nil
    }
  }
  
  func checkAuthorizedFeaturesPermissions() {
    Task {
      let permissions = viewModel.resolvedPermissions.map(\.type)
      let fetches = PermissionService.Fetcher(permissions: permissions)
      for await (permission, status) in fetches {
        if status == .authorized {
          viewModel.allowedPermissions.insert(permission)
        }
      }
    }
  }
  
//  @MainActor
  func requestPermissions() async {
    let permissions = viewModel.resolvedPermissions.map(\.type)
    let requests = PermissionService.Requester(permissions: permissions)
    for await (permission, status) in requests {
      if status == .authorized {
        viewModel.allowedPermissions.insert(permission)
      }
    }
  }

}

// MARK: - IconLabel

public extension Permissions.ViewModel {
  
  struct Icon {
      var icon: UIImage
      var color: UIColor
      var selectionColor: UIColor
      var text: NSAttributedString
  }
  
}
private final class IconLabel: UIBase.View {
  
  private enum Const {
    static let spacing = CGFloat(12)
  }
  
  private let icon = IconView()
  private let label = UIBase.Label {
    $0.numberOfLines = 1
    $0.setDynamicFont(font: .systemFont(ofSize: isPad ? 24 : 16, weight: .regular),
                      maximumPointSize: isPad ? 30 : 20)
    $0.textAlignment = isRTL ? .right : .left
    $0.adjustsFontSizeToFitWidth = true
    $0.minimumScaleFactor = 0.8
  }
  
  override func setup() {
    super.setup()
    addSubviews(icon, label)
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    if isRTL {
      label.pin.left()
        .vCenter().maxHeight(bounds.height).sizeToFit(.height)
      icon.pin.left(to: label.edge.right).marginLeft(Const.spacing)
        .vCenter().maxHeight(bounds.height).sizeToFit(.height)
    }
    else {
      icon.pin.left()
        .vCenter().maxHeight(bounds.height).sizeToFit(.height)
      label.pin.left(to: icon.edge.right).marginLeft(Const.spacing)
        .vCenter().maxHeight(bounds.height).sizeToFit(.height)
    }
  }
  
  override func sizeThatFits(_ size: CGSize) -> CGSize {
    let iconHeight = icon.sizeThatFits(size).height
    let textHeight = label.sizeThatFits(size).height
    let h = max(iconHeight, textHeight)
    if isRTL {
      return CGSize(width: icon.frame.maxX, height: h)
    }
    else {
      return CGSize(width: label.frame.maxX, height: h)
    }
  }
  
  // MARK: - Public
  
  typealias Data = Permissions.ViewModel.Icon
  func apply(data: Data) {
    defer { setNeedsLayout() }
    
    icon.setup(with: .init(
      image: data.icon,
      color: data.color,
      selectionColor: data.selectionColor
    ))
    label.attributedText = data.text
  }
  
}

// MARK: - IconView

extension IconLabel {
  
  final class IconView: UIBase.View {
    
    private let backView = UIBase.View()
    private let imageView = UIBase.ImageView()
    
    override func setup() {
      super.setup()
      addSubviews(backView, imageView)
    }
    
    override func layoutSubviews() {
      super.layoutSubviews()
      let size = min(bounds.size.width, bounds.size.height)
      backView.pin.center().size(size)
      imageView.pin.center()
        .sizeToFit().maxHeight(size * 0.9).maxWidth(size * 0.9)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
      let minSide = min(size.width, size.height)
      let maxSize = 48.ui(.paywall)
      let side = min(maxSize, minSide)
      let result = CGSize(width: side, height: side).ui(.paywall)
      return result
    }
    
    // MARK: - Public
    
    struct Data {
      let image: UIImage
      let color: UIColor
      let selectionColor: UIColor
    }
    func setup(with data: Data) {
      defer { setNeedsLayout() }
      
      imageView.image = data.image
      imageView.tintColor = data.color
      backView.backgroundColor = data.color.withAlphaComponent(0.1)
      backView.layer.cornerRadius = 10
      backView.layer.borderColor = data.selectionColor.cgColor
      backView.layer.borderWidth = 3
    }
    
  }
}

// MARK: - Default Features

public extension Permissions.ViewModel.Permission {
  
  enum Defaults {
    static let notifications = Permissions.ViewModel.Permission(
      type: .notifications,
      icon: PaywallCraftResources.Asset.Permissions.Feature.notifications.image,
      title: L10n.Permissions.Feature.Notifications.title,
      description: ""/*L10n.Permissions.Feature.Notifications.description*/,
      color: PaywallCraftResources.Color.Permissions.Feature.notifications.color,
      selectionColor: PaywallCraftResources.Color.Permissions.selected.color
    )
    static let locationAlways = Permissions.ViewModel.Permission(
      type: .locationAlways,
      icon: PaywallCraftResources.Asset.Permissions.Feature.location.image,
      title: L10n.Permissions.Feature.Location.title,
      description: ""/*L10n.Permissions.Feature.Location.description*/,
      color: PaywallCraftResources.Color.Permissions.Feature.location.color,
      selectionColor: PaywallCraftResources.Color.Permissions.selected.color
    )
    static let locationWhenInUse = Permissions.ViewModel.Permission(
      type: .locationWhenInUse,
      icon: PaywallCraftResources.Asset.Permissions.Feature.location.image,
      title: L10n.Permissions.Feature.Location.title,
      description: ""/*L10n.Permissions.Feature.Location.description*/,
      color: PaywallCraftResources.Color.Permissions.Feature.location.color,
      selectionColor: PaywallCraftResources.Color.Permissions.selected.color
    )
    static let motion = Permissions.ViewModel.Permission(
      type: .motion,
      icon: PaywallCraftResources.Asset.Permissions.Feature.motion.image,
      title: L10n.Permissions.Feature.MotionData.title,
      description: ""/*L10n.Permissions.Feature.MotionData.description*/,
      color: PaywallCraftResources.Color.Permissions.Feature.motion.color,
      selectionColor: PaywallCraftResources.Color.Permissions.selected.color
    )
    static let photos = Permissions.ViewModel.Permission(
      type: .photos,
      icon: PaywallCraftResources.Asset.Permissions.Feature.photos.image,
      title: L10n.Permissions.Feature.Photos.title,
      description: ""/*L10n.Permissions.Feature.Photos.description*/,
      color: PaywallCraftResources.Color.Permissions.Feature.photos.color,
      selectionColor: PaywallCraftResources.Color.Permissions.selected.color
    )
  }
  
}
