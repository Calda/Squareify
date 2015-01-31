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
    
    @IBAction func nextButtonPressed(sender: AnyObject) {
        println("NEXT!")
    }
    
    func selectCell() {
        println("animating selection")
        thumbnail.alpha = 0.5
    }
    
    func deselectCell() {
        println("animating deselection")
        thumbnail.alpha = 1
    }
    
}
