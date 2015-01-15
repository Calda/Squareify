//
//  ViewController.swift
//  Squareify
//
//  Created by Cal on 1/11/15.
//  Copyright (c) 2015 Cal. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import Foundation

class ViewController: UIViewController {

    @IBOutlet weak var movingSquare: UIView!
    @IBOutlet weak var movingVideo: UIView!
    var previousTranslation : CGFloat = 0
    var translations : [(time: NSTimeInterval, delaTranslation: CGFloat)] = []
    var videoIsPlaying = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "videoFinishedPlaying", name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        translations.append(time: NSDate().timeIntervalSince1970, delaTranslation: CGFloat(0))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func panAction(sender: UIPanGestureRecognizer) {
        if videoIsPlaying {
            let translation = sender.translationInView(self.view).y
            let deltaTranslation = translation - previousTranslation
            if abs(deltaTranslation) < 20 {
                updateSelectionPosition(deltaTranslation)
            } else if abs(sender.velocityInView(self.view).y) > 800 {
                updateSelectionPosition(deltaTranslation)
            }
            previousTranslation = translation
        }
    }
    
    func updateSelectionPosition(deltaY: CGFloat) {
        let frameHeight = movingSquare.frame.size.height
        let squareHeight = frameHeight / 3
        let screenHeight = self.view.frame.height
        var newY = movingSquare.frame.origin.y + deltaY
        
        //keep center square from going off top of screen
        if newY < -squareHeight {
            newY = -squareHeight
        }
        
        //keep center square from going off bottom of screen
        if newY > -(2 * squareHeight - screenHeight) {
            newY = -(2 * squareHeight - screenHeight)
        }
        
        movingSquare.frame.origin.y = newY
        translations.append(time: NSDate().timeIntervalSince1970, delaTranslation: deltaY)
        
    }
    
    func videoFinishedPlaying() {
        videoIsPlaying = false
        println("video finished playing")
        exportVideo()
        println(translations)
    }
    
    func exportVideo() {
        let asset = AVAsset.assetWithURL(NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("testvideo", ofType: "mov")!)) as AVAsset
        
        let clipVideoTrack = asset.tracksWithMediaType(AVMediaTypeVideo)[0] as AVAssetTrack
        let videoComposition = AVMutableVideoComposition()
        videoComposition.frameDuration = CMTimeMake(1, 30)
        videoComposition.renderSize = CGSizeMake(clipVideoTrack.naturalSize.width, clipVideoTrack.naturalSize.width)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(60, 30))
        
        let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: clipVideoTrack)
        let squareSize = Int(clipVideoTrack.naturalSize.width)
        let squareOffsetFromTop : CGFloat = -CGFloat((Int(clipVideoTrack.naturalSize.height) - squareSize)/2)
        var previous = (keyframe: translations[0], transform: CGAffineTransformMakeTranslation(0, squareOffsetFromTop))
        var initialTime = translations[0].time
        transformer.setTransform(previous.transform, atTime: CMTimeMake(0, 30))
        for (time, deltaTranslation) in translations {
            let previousY = previous.transform.ty
            let transformation = CGAffineTransformMakeTranslation(0, previousY - deltaTranslation)
            let deltaTime = Double(time - initialTime)
            transformer.setTransform(transformation, atTime: CMTimeMake(Int64(deltaTime * 1000), 1000))
            previous = ((time, deltaTranslation), transformation)
        }
        
        instruction.layerInstructions = NSArray(object: transformer)
        videoComposition.instructions = NSArray(object: instruction)
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
        let exportURL = NSURL.fileURLWithPath(documentsPath.stringByAppendingFormat("/CroppedVideo.mp4"))
        
        let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        exporter.videoComposition = videoComposition
        exporter.outputURL = exportURL
        exporter.outputFileType = AVFileTypeQuickTimeMovie
        exporter.exportAsynchronouslyWithCompletionHandler({
            dispatch_async(dispatch_get_main_queue(), {
                self.exportDidFinish(exporter)
            })
        })
        
    }
    
    func exportDidFinish(exporter: AVAssetExportSession) {
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier? == "showMovie" {
            let playerController = segue.destinationViewController as AVPlayerViewController
            playerController.player = AVPlayer(URL: NSBundle.mainBundle().URLForResource("testvideo", withExtension: "mov"))
        }
    }
}

