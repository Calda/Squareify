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
    @IBOutlet weak var backBarButton: UIBarButtonItem!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var styleArrow: UIImageView!
    
    var fetch : PHFetchResult?
    let imageManager = PHImageManager()
    var playerController : AVPlayerViewController?
    
    //will change for iPhone 4S support
    @IBOutlet weak var playerViewAspectConstraint: NSLayoutConstraint!
    @IBOutlet weak var welcomeText: UILabel!
    @IBOutlet weak var playerContainerAspectConstraint: NSLayoutConstraint!
    @IBOutlet weak var playerContainerMarginConstraint: NSLayoutConstraint!
    
    //original positions for items that will animate
    var originalPlayerPosition : CGPoint?
    var originalStillViewerPosition : CGPoint?
    var originalArrowPosition : CGPoint?
    
    
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
        
        //save original positions for items that will animate
        originalPlayerPosition = playerContainer.frame.origin
        originalStillViewerPosition = stillFrameViewer.frame.origin
        originalArrowPosition = styleArrow.frame.origin
    }
    
    
    override func viewDidDisappear(animated: Bool) {
        if let player = playerController?.player{
            player.pause()
        }
    }

    
    /**
    *
    *  Video Selection Picker
    *
    */
    
    
    func displayVideoThumbnails(){
        let videoOptions = PHFetchOptions()
        videoOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetch = PHAsset.fetchAssetsWithMediaType(PHAssetMediaType.Video, options: videoOptions)
        self.automaticallyAdjustsScrollViewInsets = false
        pickerCollection.reloadData()
    }
    
    
    //displays user selected video, unselects previous
    var currentSelected : NSIndexPath?
    
    func selectAndDisplay(selectionIndex: NSIndexPath) {
        if let previousIndex = currentSelected {
            let previousCell = pickerCollection.cellForItemAtIndexPath(previousIndex) as PickerCell?
            previousCell?.deselectCell()
        } else { //this is the first video selected
            nextBarButton.enabled = true
        }
        let currentCell = pickerCollection.cellForItemAtIndexPath(selectionIndex) as PickerCell?
        currentCell?.selectCell()
        currentSelected = selectionIndex
        
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
            stillFrameViewer.frame.origin = originalStillViewerPosition!
        }
        
        //get asset for new video
        let index = selectionIndex.indexAtPosition(1)
        if let asset = fetch?.objectAtIndex(index) as? PHAsset {
            imageManager.requestAVAssetForVideo(asset, options: nil, resultHandler: { video, audio, info in
                self.playerController?.videoGravity = "AVLayerVideoGravityResizeAspectFill"
                self.playerController?.player = AVPlayer(playerItem: AVPlayerItem(asset: video))
                self.playerController?.player.play()
            })
            //animate in player
            playerContainer.frame.origin = CGPointMake(-playerContainer.frame.width, playerContainer.frame.origin.y)
            UIView.animateWithDuration(1.0, delay: 0.25, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: nil, animations: {
                    self.playerContainer.frame.origin = self.originalPlayerPosition!
                }, completion: nil)
            
            if !welcomeView.hidden { //is first selection
                playerContainer.hidden = false
                let arrowStart = CGPointMake(-styleArrow.frame.width, styleArrow.frame.origin.y)
                styleArrow.frame.origin = arrowStart
                let welcomeViewEnd = CGPointMake(welcomeView.frame.origin.x + welcomeView.frame.width, welcomeView.frame.origin.y)
                UIView.animateWithDuration(1.0, delay: 0.25, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: nil, animations: {
                        self.welcomeView.frame.origin = welcomeViewEnd
                    }, completion: { success in
                        self.welcomeView.hidden = true
                })
                UIView.animateWithDuration(1.25, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: nil, animations: {
                        self.styleArrow.frame.origin = self.originalArrowPosition!
                    }, completion: nil)
            }
            else { //is not first selection
                //animate out still frame viewer
                let newStillFramePosition = CGPointMake(originalPlayerPosition!.x + playerContainer.frame.width, originalStillViewerPosition!.y)
                UIView.animateWithDuration(1.0, delay: 0.25, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: nil, animations: {
                        self.stillFrameViewer.frame.origin = newStillFramePosition
                    }, completion: nil)
                //bounce arrow
                let newArrowPosition = CGPointMake(originalArrowPosition!.x - 35, originalArrowPosition!.y)
                UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 10, options: nil, animations: {
                        self.styleArrow.frame.origin = newArrowPosition
                    }, completion: nil)
                UIView.animateWithDuration(1.0, delay: 0.3, usingSpringWithDamping: 0.4, initialSpringVelocity: 0, options: nil, animations: {
                        self.styleArrow.frame.origin = self.originalArrowPosition!
                    }, completion: nil)
            }
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
    * Transition to and from Duration editor
    */


    @IBAction func nextButtonPressed(sender: AnyObject) {
        let newPickerOrigin = CGPointMake(-self.view.frame.width * 2, pickerCollection.frame.origin.y)
        UIView.animateWithDuration(1.0, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: nil, animations: {
            self.pickerCollection.frame.origin = newPickerOrigin
            }, completion: nil)
        nextBarButton.enabled = false
        backBarButton.tintColor = nextBarButton.tintColor
        backBarButton.enabled = true
    }
    
    
    @IBAction func backButtonPressed(sender: AnyObject) {
        let newPickerOrigin = CGPointMake(0, pickerCollection.frame.origin.y)
        UIView.animateWithDuration(1.0, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: nil, animations: {
            self.pickerCollection.frame.origin = newPickerOrigin
            }, completion: nil)
        backBarButton.enabled = false
        backBarButton.tintColor = UIColor.clearColor()
        nextBarButton.enabled = true
    }
    
    /**
    * Ad Delegate - bring the banner on screen when it has an ad to display, move off when it doesn't
    */
    
    var originalPickerHeight : CGFloat?
    
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        
        //keep the video picker from being taller than it has space to be
        if originalPickerHeight == nil {
            originalPickerHeight = pickerCollection.frame.height
        }
        if pickerCollection.frame.height > originalPickerHeight {
            pickerCollection.frame.size = CGSize(width: pickerCollection.frame.width, height: originalPickerHeight!)
        }
        
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
            var newPickerSize = CGSizeMake(pickerCollection.frame.width, pickerCollection.frame.height + banner.frame.height)
            if newPickerSize.height > originalPickerHeight {
                newPickerSize.height = originalPickerHeight!
            }
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