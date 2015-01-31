//
//  PickerController.swift
//  Squareify
//
//  Created by Cal on 1/24/15.
//  Copyright (c) 2015 Cal. All rights reserved.
//

import UIKit
import Photos
import AVKit
import iAd

class SquareifyController : UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, ADBannerViewDelegate {
    
    @IBOutlet weak var pickerController: UICollectionView!
    @IBOutlet weak var playerContainer: UIView!
    @IBOutlet weak var adBanner: ADBannerView!
    
    var fetch : PHFetchResult?
    let imageManager = PHImageManager()
    var playerController : AVPlayerViewController?
    
    override func viewWillAppear(animated: Bool) {
        //get photos auth
        let authorization = PHPhotoLibrary.authorizationStatus()
        if authorization == PHAuthorizationStatus.NotDetermined {
            PHPhotoLibrary.requestAuthorization() { status in
                if status == PHAuthorizationStatus.Authorized {
                    self.displayVideoThumbnails()
                }
            }
        }
        else if authorization == PHAuthorizationStatus.Authorized {
            displayVideoThumbnails()
        }
    }

    func displayVideoThumbnails(){
        let videoOptions = PHFetchOptions()
        videoOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetch = PHAsset.fetchAssetsWithMediaType(PHAssetMediaType.Video, options: videoOptions)
        println(fetch)
        self.automaticallyAdjustsScrollViewInsets = false
        pickerController.reloadData()
    }
    
    //setup embeded viewer
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier? == "embedViewer" {
            playerController = (segue.destinationViewController as AVPlayerViewController)
        }
    }
    
    /**
     * Picker View Data Source
    **/
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let count = fetch?.count {
            return count
        }
        else {
            return 0
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PickerCell", forIndexPath: indexPath) as PickerCell
        cell.backgroundColor = UIColor.blackColor()
        
        let index = indexPath.indexAtPosition(1)
        if let asset = fetch?.objectAtIndex(index) as? PHAsset {
            imageManager.requestImageForAsset(asset, targetSize: cell.frame.size, contentMode: PHImageContentMode.AspectFill, options: nil, resultHandler: { result, info in
                cell.thumbnail.image = result
                cell.duration = asset.duration
            })
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: 90, height: 90)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 5
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? PickerCell {
            cell.blurEffect.hidden = false
        }
        let index = indexPath.indexAtPosition(1)
        if let asset = fetch?.objectAtIndex(index) as? PHAsset {
            imageManager.requestAVAssetForVideo(asset, options: nil, resultHandler: { video, audio, info in
                self.playerController?.player = AVPlayer(playerItem: AVPlayerItem(asset: video))
                self.playerController?.player.play()
                self.playerController?.videoGravity = "AVLayerVideoGravityResizeAspectFill"
                self.playerController?.player
            })
            playerContainer.hidden = false
        }
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? PickerCell {
            cell.blurEffect.hidden = true
        }
    }
    
    /**
    * Ad Delegate
    */
    
    var bannerStarts : [ADBannerView : CGPoint] = [:]
    
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        println(banner)
        if bannerStarts[banner] == nil {
            bannerStarts.updateValue(banner.frame.origin, forKey: banner)
            
            let height = banner.frame.height
            let newPosition = CGPointMake(banner.frame.origin.x, banner.frame.origin.y - height)
            UIView.animateWithDuration(1.0, animations: {
                banner.frame.origin = newPosition
            })
        }
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        println(banner)
        if let start = bannerStarts[banner] {
            UIView.animateWithDuration(1.0, animations: {
                banner.frame.origin = start
            })
        }
    }
    
}