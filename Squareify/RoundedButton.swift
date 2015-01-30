//
//  RoundedButton.swift
//  Squareify
//
//  Created by Cal on 1/19/15.
//  Copyright (c) 2015 Cal. All rights reserved.
//

import Foundation
import UIKit

class RoundedButton : UIButton {
    
    var topLeft : Bool = false
    var topRight : Bool = false
    var bottomLeft : Bool = false
    var bottomRight : Bool = false
    var allCorners : Bool = false
    var curve : Int = 10
    private var corners : UIRectCorner = UIRectCorner.allZeros
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if allCorners {
            corners = UIRectCorner.AllCorners
        }
        else{
            if topLeft {
                corners |= UIRectCorner.TopLeft
            }
            if topRight {
                corners |= UIRectCorner.TopRight
            }
            if bottomLeft {
                corners |= UIRectCorner.BottomLeft
            }
            if bottomRight {
                corners |= UIRectCorner.BottomRight
            }
        }
        
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSizeMake(CGFloat(curve), CGFloat(curve)))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.bounds
        maskLayer.path = path.CGPath
        self.layer.mask = maskLayer
        
    }
    
}