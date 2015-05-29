//
//  PickerCellCollectionViewCell.swift
//  Squareify
//
//  Created by Cal on 1/29/15.
//  Copyright (c) 2015 Cal. All rights reserved.
//

import UIKit

class PickerCell: UICollectionViewCell {
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var thumbnail: UIImageView!
    
    var duration : NSTimeInterval = 0 {
        willSet(value){
            let minutes = Int(value) / 60
            let seconds = Int(value) % 60
            let secondsString = (seconds < 10 ? "0" : "") + "\(seconds)"
            timeLabel.text = "\(minutes):\(secondsString)"
        }
    }
    
    func selectCell() {
        UIView.animateWithDuration(1.0, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: nil, animations: {
            self.thumbnail.alpha = 0.5
        }, completion: nil)
    }
    
    func deselectCell() {
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: nil, animations: {
            self.thumbnail.alpha = 1
            }, completion: nil)
    }
    
    func playAppearAnimation() {
        self.layer.transform = CATransform3DMakeAffineTransform(CGAffineTransformMakeScale(0.0, 0.0))
        let fullScale = CATransform3DMakeAffineTransform(CGAffineTransformMakeScale(1.0, 1.0))
        UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: nil, animations: {
            self.layer.transform = fullScale
            self.alpha = 1.0
        }, completion: nil)
    }
    
}
