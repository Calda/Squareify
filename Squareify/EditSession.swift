//
//  EditSession.swift
//  Squareify
//
//  Created by Cal on 3/15/15.
//  Copyright (c) 2015 Cal. All rights reserved.
//

import Foundation
import AVFoundation
import Photos

class EditSession {
    
    let asset: AVAsset
    var edits: [Float64 : CGAffineTransform] = [:]
    
    
    init(asset: AVAsset) {
        self.asset = asset
    }
    
    
    func addTransform(time: CMTime, transform: CGAffineTransform) {
        let seconds = CMTimeGetSeconds(time)
        edits.updateValue(transform, forKey: seconds)
    }
    
    
    func export() {
        let track = asset.tracksWithMediaType(AVMediaTypeVideo)[0] as AVAssetTrack
        let correctedSize = getCorrectedAssetSize(asset)
        let composition = AVMutableVideoComposition()
        composition.frameDuration = CMTimeMake(1, 30)
        composition.renderSize = CGSizeMake(correctedSize.width, correctedSize.width)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration)
        
        let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        var preferred = asset.preferredTransform
        preferred.ty = (correctedSize.height - correctedSize.width) / -2
        
        for time64 in edits.keys {
            let time = CMTimeMakeWithSeconds(time64, 1000)
            let frame = edits[time64]!
            let transform = CGAffineTransformConcat(preferred, frame)
            transformer.setTransform(transform, atTime: time)
        }
        
        instruction.layerInstructions = [transformer]
        composition.instructions = [instruction]
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
        let exportURL = NSURL.fileURLWithPath(documentsPath.stringByAppendingFormat("/editedVideo.mp4"))
        
        let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        exporter.videoComposition = composition
        exporter.outputURL = exportURL
        exporter.outputFileType = AVFileTypeQuickTimeMovie
        exporter.exportAsynchronouslyWithCompletionHandler({
            dispatch_async(dispatch_get_main_queue(), {
                println("done?")
            })
        })
    }
    
    
    func xscale(t: CGAffineTransform) -> CGFloat {
        return sqrt(t.a * t.a + t.c * t.c)
    }
    
    
    func getCorrectedAssetSize(asset: AVAsset) -> CGSize {
        
        let track = asset.tracksWithMediaType(AVMediaTypeVideo)[0] as AVAssetTrack
        let naturalSize = track.naturalSize
        println(naturalSize)
        let transform = asset.preferredTransform
        let rect = CGRectMake(0, 0, naturalSize.width, naturalSize.height)
        let correctedRect = CGRectApplyAffineTransform(rect, transform)
        println(correctedRect.size)
        return correctedRect.size
    }
    
}