//
//  Paywall~TwoButtonsVC.swift
//
//  Created by dDomovoj on 6/9/22.
//

import UIKit

import RevenueCat

import PinLayout
import SwiftyAttributes
import StackCraft

import UIBase
import UICommon
import PaywallCraftResources
import PaywallCraftUI

public extension Config.UI {

  typealias Paywall = PaywallCraftCore.Paywall.ViewModel

}

extension Paywall {

  public struct ViewModel {

      private enum Const {
          static let tryFreeButtonFontSize: CGFloat = isPad ? 22 : 17
      }
      
    private static let additionalAttributes: [SwiftyAttributes.Attribute] = [
      .font(UIFont.systemFont(ofSize: isPad ? 16 : 13)),
      .textColor(Color.Paywall.dopButton.color),
      .underlineStyle(.single)
    ]

    public var fadeColors: [UIColor] = [
      Color.Paywall.background.color,
      Color.Paywall.background.color.withAlphaComponent(0),
    ]
    public var bgColor = Color.Main.back.color
    public var closeColor = Color.Paywall.title.color
    
    public var image = VM.Image(Asset.Paywall.image.image)
//      .size(.computed({ img -> CGSize in
//      if img.aspectRatio == 0 { return .zero }
//
//      let ctx = img.ctx
//      let h: CGFloat
//      switch (ctx.isPad, ctx.isLandscape) {
//      case (_, true): // both, ladscape
//        let t = (img.containerSize.height / 768.ui(.paywall))
//          .normalized(by: 0.5498046875...0.931640625)
//        h = min(
//          img.containerSize.width / img.aspectRatio * 0.8,
//          img.containerSize.height * .lerp(0.3, 0.6, t)
//        )
//      case (true, _): // pad, portrait
//        let t = img.containerSize.height / 1024.ui(.paywall)
//          .normalized(by: 0.4908424908424908...0.9494505494505494)
//        h = min(
//          768.ui(ctx.uiIntent) / img.aspectRatio * 0.8,
//          img.containerSize.height * .lerp(0.4, 0.8, t)
//        )
//      case (false, _): // phone, portrait
//        h = 375.ui(ctx.uiIntent) / img.aspectRatio * 0.8
//      }
//
//      let w = h * img.aspectRatio
//      return CGSize(width: w, height: h)
//    }))

    public var title = L10n.Paywall.TwoButtons.title
    public var titleColor = Color.Paywall.title.color

    public var subtitle = L10n.Paywall.TwoButtons.subtitle
    public var subtitleColor = Color.Paywall.infoTitle.color

    public var text = L10n.Paywall.TwoButtons.text
    public var textColor = Color.Main.text.color

    public var trial = L10n.Paywall.tryFreeAndSubscribe
    public var trialTextColor = UIColor.white
    public var trialBgColor = Color.Paywall.continue.color

    public var instantShouldShowSubtitle = true
    public var instantBgColor = Color.Main.back.color
    public var instantBorderColor = Color.Paywall.continue.color
    public var instantTitleColor = Color.Paywall.continue.color
    public var instantSubtitleColor = Color.Paywall.title.color

    public var terms = L10n.Paywall.Button.terms.withAttributes(Self.additionalAttributes)
    public var policy = L10n.Paywall.Button.privacy.withAttributes(Self.additionalAttributes)
    public var restore = L10n.Paywall.Button.restore.withAttributes(Self.additionalAttributes)

    public init() { }

    fileprivate func apply(to view: InitialVC) {
      defer { view.view.setNeedsLayout() }

      view.view.backgroundColor = bgColor
      view.closeButton.tintColor = closeColor
      view.bgView.colors = fadeColors
      view.imageView.image = image.uiImage

      view.titleLabel.text = title
      view.subtitleLabel.text = subtitle

      view.titleLabel.textColor = titleColor
      view.subtitleLabel.textColor = subtitleColor
      view.textLabel.textColor = textColor

      view.trialButton.setTitle(trial, for: .normal)
      view.trialButton.setBackgroundImage(trialBgColor.image(), for: .normal)
      view.trialButton.setTitleColor(trialTextColor, for: .normal)

      view.instantButton.indicatorColor = instantBorderColor
      view.instantButton.color = instantBgColor
      view.instantButton.borderColor = instantBorderColor

      zip(
        [view.termsButton, view.privacyButton, view.restoreButton],
        [terms, policy, restore]
      ).forEach { button, text in
        button.setAttributedTitle(text, for: .normal)
        button.explicitIntrinsicContentSize = CGSize(width: text.string.size().width, height: UIView.noIntrinsicMetric)
      }

      view.textLabel.attributedText = textWithTrial(for: view.trialProduct)
      
      view.instantButton.setContent(instantText(for: view.instantProduct).flatMap { .text($0) } ?? .loading)
      view.instantButton.setAttributedTitle(instantText(for: view.instantProduct), for: .normal)
    }

    private func textWithTrial(for product: StoreProduct?) -> NSAttributedString {
      guard let product = product else {
        return NSAttributedString(string: text, swiftyAttributes: [])
      }

      let price = product.localizedPricePerPeriod()
      let trialCount = product.trialCount()
      var result: NSMutableAttributedString

      if trialCount == 7 {
        result = L10n.Paywall.TwoButtons.textFormat7(trialCount, price)
          .withFont(.systemFont(ofSize: 17.ui(.paywall), weight: .light))
      }
      else {
        result = L10n.Paywall.TwoButtons.textFormat(trialCount, price)
          .withFont(.systemFont(ofSize: 17.ui(.paywall), weight: .light))
      }

      let priceRange = (result.string as NSString).range(of: price)
      if priceRange.location != NSNotFound && priceRange.length > 0 {
          result.addAttributes([.font(.systemFont(ofSize: InitialVC.Const.tryFreeButtonFontSize + 2, weight: .bold))], range: priceRange)
      }
      return result
    }

    private func instantText(for product: StoreProduct?) -> NSAttributedString? {
      guard let product = product,
            let period = product.subscriptionPeriod
      else { return nil }

      var shouldAddSubtitle = instantShouldShowSubtitle
      if shouldAddSubtitle {
        if period.unit == .month && period.value <= 1 {
          shouldAddSubtitle = false
        }
        if period.unit.isAny(of: .day, .week) {
          shouldAddSubtitle = false
        }
      }

      let suffix = shouldAddSubtitle ? "\n" : ""
      var result = (product.localizedPricePerPeriod() + suffix)
        .withFont(.systemFont(ofSize: isPad ? 24 : 18, weight: .semibold))
        .withTextColor(instantTitleColor)

      if shouldAddSubtitle {
        result += L10n.Paywall.TwoButtons.infoJust(product.localizedMonthlyPriceSlashMonth())
          .withFont(.systemFont(ofSize: isPad ? 16 : 12, weight: .regular))
          .withTextColor(instantSubtitleColor)
      }

      result = result
        .withParagraphStyle(NSMutableParagraphStyle { $0.alignment = .center })

      return result
    }

  }

  final class InitialVC: ViewController {

    enum Const {
      static let additionalButtonsHeight = CGFloat(50)
      static let ctaButtonSize = CGSize(width: isPad ? 400 : 285.ui(.paywall), height: isPad ? 70 : 50)
        static let tryFreeButtonFontSize: CGFloat = isPad ? 22 : 17
    }

    fileprivate var trialProduct: StoreProduct?
    fileprivate var instantProduct: StoreProduct?

    var viewModel = ViewModel() {
      didSet { viewModel.apply(to: self) }
    }

    // MARK: UI

    private let contentView = UIBase.View {
      $0.backgroundColor = .clear
    }

    fileprivate lazy var closeButton = UIBase.Button {
      $0.setImage(Asset.Paywall.cross.image.withRenderingMode(.alwaysTemplate), for: .normal)
    }.asAccessibilityElement(L10n.General.Button.close, traits: .button)

    private let vStackView = VStackView()

    fileprivate let bgView = UICommon.GradientView { $0.direction = .down }
    fileprivate let imageView = UIBase.ImageView { $0.contentMode = .scaleAspectFit }

//    private var image: VStackView.Component {
//      imageView
//        .vComponent
//        .skipLayout()
//        .height(.fixed(viewModel.image.calculateSize().height))
//    }

    fileprivate let titleLabel = UIBase.Label {
      $0.setDynamicFont(font: .systemFont(ofSize: 40.ui(.paywall), weight: .bold))
      $0.numberOfLines = 1
      $0.adjustsFontSizeToFitWidth = true
      $0.minimumScaleFactor = 0.7
      $0.textAlignment = isRTL ? .right : .left
    }
    fileprivate let subtitleLabel = UIBase.Label {
      $0.setDynamicFont(font: .systemFont(ofSize: 17.ui(.paywall), weight: .semibold))
      $0.numberOfLines = 1
      $0.textAlignment = isRTL ? .right : .left
    }
    fileprivate let textLabel = UIBase.Label {
      $0.setDynamicFont(font: .systemFont(ofSize: 17.ui(.paywall), weight: .regular))
      $0.numberOfLines = 0
      $0.textAlignment = isRTL ? .right : .left
      $0.verticalAlignment = .top
    }

    fileprivate let trialButton = UIBase.Button {
      $0.titleLabel?.adjustsFontSizeToFitWidth = true
      $0.titleLabel?.minimumScaleFactor = 0.75
      $0.titleLabel?.numberOfLines = 2
      $0.titleLabel?.textAlignment = .center
      $0.contentLayout = .alignByEdges(spacing: 10.ui(.paywall),
                                       padding: UIEdgeInsets(top: 0, left: 10.ui(.paywall), bottom: 0, right: 10.ui(.paywall)))
        $0.titleLabel?.setDynamicFont(font: .systemFont(ofSize: Const.tryFreeButtonFontSize, weight: .bold),
                                    maximumPointSize: isPad ? 26 : 20)
      $0.layer.cornerRadius = 13
      $0.clipsToBounds = true
    }.asAccessibilityElement(traits: .button)

    fileprivate let instantButton = PaywallCraftUI.LoadableButton {
      $0.titleLabel?.numberOfLines = 2
      $0.layer.borderWidth = 1
      $0.layer.cornerRadius = 13
      $0.clipsToBounds = true
    }.asAccessibilityElement(traits: .button)

    private let additionalButtonsContainer = UIView()
    fileprivate let termsButton = UIBase.Button().asAccessibilityElement(traits: .link)
    fileprivate let privacyButton = UIBase.Button().asAccessibilityElement(traits: .link)
    fileprivate let restoreButton = UIBase.Button().asAccessibilityElement(traits: .button)

    // MARK: - Lifecycle

    override func loadView() {
      super.loadView()
      
      view.addSubviews(contentView, closeButton)

      contentView.addSubviews(imageView, vStackView, textLabel, additionalButtonsContainer)
      additionalButtonsContainer.addSubviews(termsButton, privacyButton, restoreButton)
    }

    override func viewDidLoad() {
      super.viewDidLoad()

      trialButton.addAction { [weak self] _ in self?.purchase(self?.trialProduct) }
      instantButton.addAction { [weak self] _ in self?.purchase(self?.instantProduct) }

      closeButton.addAction { [weak self] _ in
        guard let self else { return }
        
        var e = self.createEvent()
        e.makeFinal()
        self.handleEventAndCloseIfFinal(e)
      }

      termsButton.addAction { [weak self] _ in self?.showTerms() }
      privacyButton.addAction { [weak self] _ in self?.showPolicy() }
      restoreButton.addAction { [weak self] _ in self?.restorePurchases() }

      updateProducts()
      viewModel.apply(to: self)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
      super.traitCollectionDidChange(previousTraitCollection)
      
      viewModel.apply(to: self)
    }

    override func didUpdatePaywallStatus() {
      guard updateProducts() else { return }

      viewModel.apply(to: self)
    }

    override func viewDidLayoutSubviews() {
      super.viewDidLayoutSubviews()
      
      let w = view.bounds.width
      let contentFitWidth = isPad
      ? min(w - 20.ui, 480.ui(.paywall))
      : 285.ui(.paywall)
      
      let safeArea = view.pin.safeArea
      if isPad && isPortrait {
        bgView.pin.top().horizontally().height(35%)
      }
      else {
        bgView.pin.top().horizontally().height(280.ui(.paywall) + safeArea.top)
      }
      
      if isRTL {
        closeButton.pin.start(32).size(16).top(max(safeArea.top + 16, 32))
      }
      else {
        closeButton.pin.end(32).size(16).top(max(safeArea.top + 16, 32))
      }
      contentView.pin.top(safeArea).bottom(safeArea).hCenter().width(contentFitWidth)

      additionalButtonsContainer.pin.bottom().start().end().height(Const.additionalButtonsHeight)
      termsButton.pin.start().top().bottom().sizeToFit()
      privacyButton.pin.top().bottom().hCenter().sizeToFit()
      restoreButton.pin.end().top().bottom().sizeToFit()

      vStackView.pin.start().end().top().bottom(to: additionalButtonsContainer.edge.top)
      vStackView.layoutIfNeeded()
      if viewModel.image.containerSize != vStackView.bounds.size {
        viewModel.image.containerSize = vStackView.bounds.size
      }
      
      reloadUI()
      textLabel.frame.size.height += vStackView.spacing(after: textLabel.vComponent) * 0.8

//      imageView.pin.hCenter()
////        .width(isPortrait && isMap ? view.bounds.width : vStackView.bounds.width)
//        .width(vStackView.bounds.width)
//        .top(to: vStackView.edge.top).marginTop(vStackView.spacing(before: image))
//        .height(vStackView.height(of: image))
      
      let imageMinY = safeArea.top
      let imageMaxY = vStackView.spacing(before: titleLabel.vComponent)
      let imageCenterY = (imageMinY + imageMaxY) * 0.5
      let imageMaxHeight = imageMaxY - imageMinY
      let imageMaxWidth = contentFitWidth
      let imageSize = min(imageMaxHeight, imageMaxWidth)
      imageView.pin.size(imageSize).hCenter()
        .vCenter(to: contentView.edge.top).marginTop(imageCenterY)
    }

  }
}

// MARK: - Private

private extension Paywall.InitialVC {

  @discardableResult
  func updateProducts() -> Bool {
    var changed = false

//    let trial = imageType == .additional ? paywall?.productsList(for: .additionTrial).first : paywall?.productsList(for: .none).first
    var products = paywall.productsList()
    
    let trial = products.first(where: { $0.introductoryDiscount?.type == .introductory })
    if let trial, let idx = products.firstIndex(of: trial) {
      products.remove(at: idx)
    }

    changed = changed || trial != trialProduct
    trialProduct = trial

    if let instProduct = products.first(where: { $0.introductoryDiscount == nil }) {
//      let instant = imageType == .additional ? paywall?.productsList(for: .additionInstant).first : instProduct
      let instant = instProduct
      changed = changed || instant != instantProduct
      instantProduct = instant
    }

    return changed
  }

  func reloadUI() {
    vStackView.reload {
      311.floating
      titleLabel.vComponent
      16.floating
      subtitleLabel.vComponent
      24.floating
      textLabel.vComponent
      40.floating
      trialButton.vComponent
        .height(.fixed(Const.ctaButtonSize.height))
        .width(.fixed(Const.ctaButtonSize.width))
        .alignment(.center)
      16.floating
      instantButton.vComponent
        .height(.fixed(Const.ctaButtonSize.height))
        .width(.fixed(Const.ctaButtonSize.width))
        .alignment(.center)
      89.floating
    }
//    vStackView.reload {
////      if isPad && isMap && isPortrait {
////        44.fixed
////      }
////      else {
//        6.floating
////      }
//      image
//      24.floating
//      titleLabel.vComponent
//      8.floating
//      subtitleLabel.vComponent
//      20.floating
//      textLabel.vComponent
//      40.floating
//      trialButton.vComponent
//        .height(.fixed(Const.ctaButtonSize.height))
//        .width(.fixed(Const.ctaButtonSize.width))
//        .alignment(.center)
//      16.floating
//      instantButton.vComponent
//        .height(.fixed(Const.ctaButtonSize.height))
//        .width(.fixed(Const.ctaButtonSize.width))
//        .alignment(.center)
//      40.floating
//    }
  }

}
