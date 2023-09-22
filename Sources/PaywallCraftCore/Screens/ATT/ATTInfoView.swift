//
//  ATTInfoView.swift
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

class ATTInfoView: View {
  
  enum ViewType {
    case experience
    case content
  }
  
  private let image = ImageView {
    $0.contentMode = .scaleAspectFit
  }
  
  private let label = Label {
    $0.setDynamicFont(font: .systemFont(ofSize: isPad ? 22.ui : 18.ui),
                      maximumPointSize: isPad ? 30.ui : 24.ui)
    $0.textColor = Color.Main.text.color
    $0.numberOfLines = 3
    $0.adjustsFontSizeToFitWidth = true
    $0.minimumScaleFactor = 0.5
  }
  
  init(type: ViewType) {
    super.init(frame: .zero)
    
    addSubviews(image, label)
    
    switch type {
    case .experience:
      image.image = Assets.Images.Att.experience.image
      label.text = L10n.Att.Request.Description.first
    case .content:
      image.image = Assets.Images.Att.content.image
      label.text = L10n.Att.Request.Description.second
    }
  }
  
  required public init?(coder aDecoder: NSCoder) { return nil }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    image.pin
      .vertically().left()
      .aspectRatio(1)
    
    label.pin
      .vertically().right()
      .left(to: image.edge.right).marginLeft(20.ui)
  }
}
