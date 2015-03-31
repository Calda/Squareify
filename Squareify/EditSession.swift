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
    let previewSize : CGSize
    
    init(asset: AVAsset, previewSize: CGSize) {
        self.asset = asset
        self.previewSize = previewSize
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
        var preferred = track.preferredTransform
        if correctedSize == track.naturalSize { //no adjustments
            //preferred.ty = (correctedSize.height - correctedSize.width) / -2
        }
        
        
        let ratioPreviewToExport = previewSize.width / composition.renderSize.width
        
        for time64 in edits.keys {
            let time = CMTimeMakeWithSeconds(time64, 1000)
            let frame = edits[time64]!
            
            let adjustedForPreferred = CGAffineTransformConcat(preferred, frame)
            
            //fix translation
            let scale = xscale(adjustedForPreferred)
            var txActual = (frame.tx / ratioPreviewToExport) - adjustedForPreferred.tx
            var tyActual = (frame.ty / ratioPreviewToExport) - adjustedForPreferred.ty
            
            //fix scale
            txActual += (correctedSize.width - scale * correctedSize.width) / 2
            tyActual += (correctedSize.width - scale * correctedSize.height) / 2
            
            //fix rotation
            let angle = theta(adjustedForPreferred)
            let offset = calculateRotationOffset(angle, height: correctedSize.height, width: correctedSize.width)
            println("(\(offset.x), \(offset.y))")
            txActual -= offset.x
            txActual -= offset.y
            
            let fixed = CGAffineTransformTranslate(adjustedForPreferred, txActual / scale, tyActual / scale)
            
            transformer.setTransform(fixed, atTime: time)
        }
        
        instruction.layerInstructions = [transformer]
        composition.instructions = [instruction]
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
        let exportURL = NSURL.fileURLWithPath(documentsPath.stringByAppendingFormat("/editedVideo.mp4"))
        
        let fileManager = NSFileManager.defaultManager()
        fileManager.removeItemAtPath(exportURL!.path!, error: nil)
        
        let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        exporter.videoComposition = composition
        exporter.outputURL = exportURL
        exporter.outputFileType = AVFileTypeQuickTimeMovie
        exporter.exportAsynchronouslyWithCompletionHandler({
            dispatch_async(dispatch_get_main_queue(), {
                UISaveVideoAtPathToSavedPhotosAlbum(exportURL!.path!, nil, nil, nil)
                println("saved")
            })
        })
    }
    
    
    func xscale(t: CGAffineTransform) -> CGFloat {
        return sqrt(t.a * t.a + t.c * t.c)
    }
    
    func theta(t: CGAffineTransform) -> CGFloat {
        return atan2(t.b, t.a)
    }
    
    func calculateRotationOffset(angle: CGFloat, height: CGFloat, width: CGFloat) -> CGPoint{
        var thetaUnclamped = Double(angle)
        if thetaUnclamped < 0 {
            thetaUnclamped = (2 * M_PI) - thetaUnclamped
        }
        let h = Double(height)
        let w = Double(width)
        //radians to degrees
        let degrees = (thetaUnclamped % (2*M_PI)) * (180/M_PI)
        //clamp theta to [0,90]
        let theta = thetaUnclamped % (M_PI/2)
        
        var x : Double = 0
        var y : Double = 0
        if degrees <= 90 {
            y = w * sin(theta) //x=0
        }
        else if degrees > 90 && degrees <= 180 {
            x = h * sin(theta)
            y = w * sin(theta) + h * cos(theta)
        }
        else if degrees > 180 && degrees <= 270 {
            x = h * sin(theta) + w * cos(theta)
            y = h * cos(theta)
        }
        else { //degrees > 270
            x = w * cos(theta) //y=0
        }
        
        return CGPointMake(CGFloat(x), CGFloat(y))
    }
    
    
    func getCorrectedAssetSize(asset: AVAsset) -> CGSize {
        let track = asset.tracksWithMediaType(AVMediaTypeVideo)[0] as AVAssetTrack
        let naturalSize = track.naturalSize
        let transform = track.preferredTransform
        let rect = CGRectMake(0, 0, naturalSize.width, naturalSize.height)
        let correctedRect = CGRectApplyAffineTransform(rect, transform)
        return correctedRect.size
    }
    
}