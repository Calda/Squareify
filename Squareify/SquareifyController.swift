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
import AVFoundation
import iAd

class SquareifyController : UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, ADBannerViewDelegate {
    
    @IBOutlet weak var pickerCollection: UICollectionView!
    @IBOutlet weak var pickerHolder: UIView!
    @IBOutlet weak var playerContainer: UIView!
    @IBOutlet weak var stillFrameViewer: UIImageView!
    @IBOutlet weak var adBanner: ADBannerView!
    @IBOutlet weak var welcomeView: UIView!
    @IBOutlet weak var nextBarButton: UIBarButtonItem!
    @IBOutlet weak var playerView: UIView!
    
    var fetch : PHFetchResult?
    let imageManager = PHImageManager()
    var playerController : AVPlayerViewController?
    
    //will change for iPhone 4S support
    @IBOutlet weak var playerViewAspectConstraint: NSLayoutConstraint!
    @IBOutlet weak var welcomeText: UILabel!
    @IBOutlet weak var playerContainerAspectConstraint: NSLayoutConstraint!
    @IBOutlet weak var playerContainerMarginConstraint: NSLayoutConstraint!
    
    
    override func viewWillAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loopPlayerVideo", name: AVPlayerItemDidPlayToEndTimeNotification, object: nil) //set up video looping
        
        let screenAspect = self.view.frame.width / self.view.frame.height
        if screenAspect > (9.5/16) { //is iPhone 4S
            playerViewAspectConstraint.constant = 100
            welcomeText.font = UIFont(name: welcomeText!.font.fontName, size: 22)
            playerContainerAspectConstraint.constant = -20
            playerContainerMarginConstraint.constant = -40
        }
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
    
    
    override func viewDidAppear(animated: Bool) {
        //move ad to start off-screen
        let screenHeight = self.view.frame.height
        let offScreenOrigin = CGPointMake(0,screenHeight)
        UIView.animateWithDuration(1.0, animations: {
            self.adBanner.frame.origin = offScreenOrigin
        })
    }
    
    
    override func viewDidDisappear(animated: Bool) {
        playerController?.player.pause()
    }

    
    func displayVideoThumbnails(){
        let videoOptions = PHFetchOptions()
        videoOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetch = PHAsset.fetchAssetsWithMediaType(PHAssetMediaType.Video, options: videoOptions)
        self.automaticallyAdjustsScrollViewInsets = false
        pickerCollection.reloadData()
    }
    
    
    //displays user selected video, unselects previous
    var currentSelected : NSIndexPath?
    func selectAndDisplay(index: NSIndexPath) {
        if let previousIndex = currentSelected {
            let previousCell = pickerCollection.cellForItemAtIndexPath(previousIndex) as PickerCell?
            previousCell?.deselectCell()
        } else { //this is the first video selected
            nextBarButton.enabled = true
        }
        let currentCell = pickerCollection.cellForItemAtIndexPath(index) as PickerCell?
        currentCell?.selectCell()
        currentSelected = index
        
        //get current frame of current video
        if playerController?.player != nil {
            playerController!.player.pause()
            let currentVideoAsset = playerController!.player.currentItem.asset
            let assetTrack = (currentVideoAsset.tracksWithMediaType(AVMediaTypeVideo).first as AVAssetTrack)
            let transformedDims = CGSizeApplyAffineTransform(assetTrack.naturalSize, assetTrack.preferredTransform)
            //from experimentation, a negative width value in the transformed dims means the image will need to be rotated
            let orientation: UIImageOrientation = (transformedDims.width < 0 ? .Right : .Up)
            let generator = AVAssetImageGenerator(asset: currentVideoAsset)
            generator.requestedTimeToleranceAfter = kCMTimeZero
            generator.requestedTimeToleranceBefore = kCMTimeZero
            let lastPlayedFrame = generator.copyCGImageAtTime(playerController!.player.currentTime(), actualTime: nil, error: nil)
            stillFrameViewer.image = UIImage(CGImage: lastPlayedFrame, scale: 1.0, orientation: orientation)
            stillFrameViewer.alpha = 1
            UIView.animateWithDuration(0.75, delay: 0.25, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: nil, animations:
                { self.stillFrameViewer.alpha = 0 }, completion: nil)
        }
        
        //get asset for new video
        let index = index.indexAtPosition(1)
        if let asset = fetch?.objectAtIndex(index) as? PHAsset {
            imageManager.requestAVAssetForVideo(asset, options: nil, resultHandler: { video, audio, info in
                self.playerController?.player = AVPlayer(playerItem: AVPlayerItem(asset: video))
                self.playerController?.videoGravity = "AVLayerVideoGravityResizeAspectFill"
                self.playerController?.player.play()
            })
            playerContainer.hidden = false
            welcomeView.hidden = true
        }
    }

    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //setup embeded viewer
        if segue.identifier? == "embedViewer" {
            playerController = (segue.destinationViewController as AVPlayerViewController)
        }
        //give data to duration editor
        if segue.identifier == "pushDurationEditor" {
            let durationController = (segue.destinationViewController as DurationController)
            durationController.videoAsset = playerController?.player.currentItem.asset
            let photoAsset = fetch!.objectAtIndex(currentSelected!.indexAtPosition(1)) as PHAsset
            durationController.photoAsset = photoAsset
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
        
        let index = indexPath.indexAtPosition(1)
        if let asset = fetch?.objectAtIndex(index) as? PHAsset {
            imageManager.requestImageForAsset(asset, targetSize: cell.frame.size, contentMode: PHImageContentMode.AspectFill, options: nil, resultHandler: { result, info in
                cell.thumbnail.image = result
                cell.duration = asset.duration
            })
        }
        
        if indexPath == currentSelected {
            cell.selectCell()
        }
        else {
            cell.deselectCell()
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
        self.selectAndDisplay(indexPath)
    }
    
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        if let pickerCell = (pickerCollection.cellForItemAtIndexPath(indexPath) as? PickerCell) {
            pickerCell.deselectCell()
        }
    }
    
    
    /**
    * Ad Delegate - bring the banner on screen when it has an ad to display, move off when it doesn't
    */
    
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        
        if banner.hidden {
            
            if banner.frame.origin.y < view.frame.height { //banner is currently on screen
                banner.frame.origin = CGPointMake(0, view.frame.height)
            }
            
            banner.hidden = false
            
            let height = banner.frame.height
            let newBannerPosition = CGPointMake(banner.frame.origin.x, banner.frame.origin.y - height)
            let newPickerSize = CGSizeMake(pickerCollection.frame.width, pickerCollection.frame.height - height)
            
            UIView.animateWithDuration(1.0, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: nil, animations: {
                banner.frame.origin = newBannerPosition
                self.pickerCollection.frame.size = newPickerSize
                }, completion: nil)
        }
    }
    
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        if !banner.hidden {
            let bannerOffScreen = CGPointMake(0, view.frame.height)
            let newPickerSize = CGSizeMake(pickerCollection.frame.width, pickerCollection.frame.height + banner.frame.height)
            UIView.animateWithDuration(1.0, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: nil, animations: {
                banner.frame.origin = bannerOffScreen
                self.pickerCollection.frame.size = newPickerSize
                }, completion: { success in banner.hidden = true })
        }
    }
    
    
    //called when video ends, if the view is on screen
    func loopPlayerVideo(){
        if self.isViewLoaded() && self.view.window != nil {
            playerController?.player.seekToTime(kCMTimeZero)
            playerController?.player.play()
        }
    }
    
}