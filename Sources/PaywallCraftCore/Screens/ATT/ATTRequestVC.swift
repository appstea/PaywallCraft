//
//  ATTRequestVC.swift
//  Main
//
//  Created by Nikita Vishnevsky on 21.09.2023.
//  Copyright © 2023 AppsTea. All rights reserved.
//

import UIKit

import SwiftyAttributes
import PinLayout
import StackCraft

import UIBase
import UICommon
import PaywallCraftResources
import PaywallCraftUI

class ATTRequestVC: UIBase.ViewController {
  
  private enum Const {
      static let buttonSize: CGSize = isPad ? CGSize(width: 400.ui, height: 70) : CGSize(width: 285.ui, height: 50)
    static var contentWidth: CGFloat { (isPad && isLandscape) ? 0.6 : 0.8 }
  }

  private lazy var imageView = ImageView {
    $0.contentMode = .scaleAspectFit
    $0.image = Assets.Images.Att.back.image
  }

  private let titleLabel = Label {
    $0.text = L10n.Att.Request.title
    $0.setDynamicFont(font: .systemFont(ofSize: isPad ? 30.ui : 24.ui, weight: .medium),
                      maximumPointSize: isPad ? 38.ui : 30.ui)
    $0.textColor = Color.Onboarding.continue.color
    $0.textAlignment = isRTL ? .right : .left
    $0.adjustsFontSizeToFitWidth = true
    $0.minimumScaleFactor = 0.8
  }
  
  private let subtitleLabel = Label {
    $0.text = L10n.Att.Request.note
    $0.setDynamicFont(font: .systemFont(ofSize: isPad ? 20.ui : 16.ui),
                      maximumPointSize: isPad ? 24.ui : 20.ui)
    $0.textColor = Color.Main.text.color
    $0.textAlignment = isRTL ? .right : .left
    $0.numberOfLines = 0
    $0.adjustsFontSizeToFitWidth = true
    $0.minimumScaleFactor = 0.8
  }

  private let firstInfo = ATTInfoView(type: .experience)
  private let secondInfo = ATTInfoView(type: .content)
  
  private let stackView = VStackView {
    $0.backgroundColor = .clear
  }

  private let continueButton = Button {
    $0.layer.cornerRadius = 12
    $0.backgroundColor = Color.Onboarding.continue.color
    $0.setTitleColor(.white, for: .normal)
    $0.setTitle(L10n.Att.Request.cta, for: .normal)
    $0.titleLabel?.font = .systemFont(ofSize: isPad ? 26 : 18, weight: .medium)
  }.asAccessibilityElement()

  private var passContinuation: CheckedContinuation<Void, Never>?

    func result() async {
      await withCheckedContinuation { [weak self] c in
        self?.passContinuation = c
      }
    }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = Color.Main.back.color
    view.setNeedsLayout()
    view.addSubview(stackView)
    continueButton.addAction { [weak self] _ in
      Task { @MainActor in
        await UIService.shared?.checkIDFAAccessIfNeeded()
        self?.passContinuation?.resume(returning: Void())
        self?.passContinuation = nil
      }
    }
  }
    
  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    view.setNeedsLayout()
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
    let safeArea = view.pin.safeArea
    let contentWidth = view.bounds.width
    
    stackView.pin.hCenter().width(contentWidth).vertically(safeArea)
    
    titleLabel.frame = CGRect(x: 0, y: 0, width: Const.buttonSize.width, height: 0)
    titleLabel.sizeToFit()
    
    subtitleLabel.frame = CGRect(x: 0, y: 0, width: Const.buttonSize.width, height: 0)
    subtitleLabel.sizeToFit()

      stackView.reload {
        0.fixed
        imageView.vComponent
          .size((isPad && isPortrait) ? CGSize(width: 450.ui, height: 450.ui) : CGSize(width: 300.ui, height: 300.ui))
          .alignment(.trailing)
        9999.floating

        titleLabel.vComponent
          .size(CGSize(width: Const.buttonSize.width, height: titleLabel.frame.height))
          .alignment(.center)
        ((isPad && isPortrait) ? 40.ui : 30.ui).fixed

        firstInfo.vComponent
          .size(CGSize(width: Const.buttonSize.width, height: 60.ui))
          .alignment(.center)
        ((isPad && isPortrait) ? 25.ui : 20.ui).fixed

        secondInfo.vComponent
          .size(CGSize(width: Const.buttonSize.width, height: 60.ui))
          .alignment(.center)
        ((isPad && isPortrait) ? 40.ui : 30.ui).fixed

        subtitleLabel.vComponent
          .size(CGSize(width: Const.buttonSize.width, height: subtitleLabel.frame.height))
          .alignment(.center)
        ((isPad && isPortrait) ? 40.ui : 30.ui).fixed

        continueButton.vComponent
          .size(Const.buttonSize)
          .alignment(.center)
        60.fixed
      }
  }

}
