//
//  PlayerView.swift
//  Squareify
//
//  Created by Cal on 2/22/15.
//  Copyright (c) 2015 Cal. All rights reserved.
//

import UIKit

class PlayerView: UIView {

    let heightConstraint : NSLayoutConstraint!
    
    private var preferedHeight : CGFloat = 0
    private var heightOffset : CGFloat = 0
    var shouldShrink = false
    var actualHeight: CGFloat {
        get {
            if shouldShrink {
                return max(0, preferedHeight - heightOffset - REQUIRED_OFFEST)
            }
            else {
                return max(0, preferedHeight - REQUIRED_OFFEST)
            }
        }
    }
    
    var REQUIRED_OFFEST : CGFloat = 0

    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        //load up height constraint
        for constraint in constraints() {
            if let constraint = constraint as? NSLayoutConstraint {
                if constraint.firstAttribute == NSLayoutAttribute.Height {
                    heightConstraint = constraint
                    return
                }
            }
        }
    }
    
    
    func preferHeight(height: CGFloat, duration: NSTimeInterval, dampening: CGFloat) {
        preferedHeight = height
        updateSize(duration, dampening)
    }
    
    
    func preferAspect(aspect: CGFloat, duration: NSTimeInterval, dampening: CGFloat) {
        preferHeight(frame.width / aspect, duration: duration, dampening: dampening)
    }
    
    
    func modifyOffsetBy(offset: CGFloat, duration: NSTimeInterval, dampening: CGFloat) {
        heightOffset += offset
        updateSize(duration, dampening)
    }
    
    
    func updateSize(duration: NSTimeInterval, _ dampening: CGFloat) {
        heightConstraint.constant = actualHeight
        if duration > 0 {
            UIView.animateWithDuration(duration, delay: 0.0, usingSpringWithDamping: dampening, initialSpringVelocity: 0, options: nil, animations: {
                self.superview!.layoutIfNeeded()
            }, completion: nil)
        } else {
            self.superview?.layoutIfNeeded()
        }
    }
    
}
