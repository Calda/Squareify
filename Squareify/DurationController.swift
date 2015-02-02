//
//  DurationController.swift
//  Squareify
//
//  Created by Cal on 2/1/15.
//  Copyright (c) 2015 Cal. All rights reserved.
//

import UIKit
import AVKit
import Photos

class DurationController: UIViewController {

    var playerController: AVPlayerViewController?
    var photoAsset : PHAsset?
    var videoAsset : AVAsset?
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        println(segue.identifier)
        if segue.identifier? == "embedPlayer" {
            playerController = (segue.destinationViewController as AVPlayerViewController)
            playerController?.player = AVPlayer(playerItem: AVPlayerItem(asset: videoAsset))
        }
    }

}
