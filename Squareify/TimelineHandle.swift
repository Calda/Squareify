//
//  TimelineHandle.swift
//  Squareify
//
//  Created by Cal on 2/12/15.
//  Copyright (c) 2015 Cal. All rights reserved.
//

import Foundation
import UIKit
import AVKit

class TimelineHandle : UIView {
    
    var xMin: () -> CGFloat
    var xMax: () -> CGFloat
    var nonSelectionRect: () -> CGRect
    let nonSelectionView: UIView
    let timeline: UIView
    
    init(frame: CGRect, timeline: UIView) {
        self.timeline = timeline
        xMin = {
            return timeline.frame.origin.x
        }
        xMax = {
            return timeline.frame.origin.x + timeline.frame.width
        }
        nonSelectionRect = {
            return CGRect(x: 0, y: 0, width: timeline.frame.width, height: timeline.frame.height)
        }
        nonSelectionView = UIView(frame: nonSelectionRect())
        nonSelectionView.alpha = 0
        nonSelectionView.backgroundColor = SQ_COLOR_LIGHT
        super.init(frame: frame)
    }

    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func updatePosition(x: CGFloat) {
        self.frame.origin = CGPointMake(x, frame.origin.y)
        constrainHandle()
        nonSelectionView.frame = nonSelectionRect()
    }
    
    
    func constrainHandle() {
        let origin = self.frame.origin
        
        if origin.x < xMin() {
            self.frame.origin = CGPointMake(xMin(), origin.y)
        }
        else if origin.x > xMax() {
            self.frame.origin = CGPointMake(xMax(), origin.y)
        }
    }
    
    
    //bring nonSelectionView to front of timeline after images are presented
    func addNonSelectionView() {
        nonSelectionView.frame = nonSelectionRect()
        timeline.addSubview(nonSelectionView)
        nonSelectionView.alpha = 0.4
    }
    
}