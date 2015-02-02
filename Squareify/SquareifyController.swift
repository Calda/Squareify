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
            println(screenAspect)
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
    
    override func viewDidDisappear(animated: Bool) {
        playerController?.player.pause()
    }

    func displayVideoThumbnails(){
        let videoOptions = PHFetchOptions()
        videoOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetch = PHAsset.fetchAssetsWithMediaType(PHAssetMediaType.Video, options: videoOptions)
        println(fetch)
        self.automaticallyAdjustsScrollViewInsets = false
        pickerController.reloadData()
    }
    
    //displays user selected video, unselects previous
    var currentSelected : NSIndexPath?
    
    func selectAndDisplay(index: NSIndexPath) {
        if let previousIndex = currentSelected {
            let previousCell = pickerController.cellForItemAtIndexPath(previousIndex) as PickerCell?
            previousCell?.deselectCell()
        } else { //this is the first video selected
            nextBarButton.enabled = true
        }
        let currentCell = pickerController.cellForItemAtIndexPath(index) as PickerCell?
        currentCell?.selectCell()
        currentSelected = index
        
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
        println("new selection")
        self.selectAndDisplay(indexPath)
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        if let pickerCell = (pickerController.cellForItemAtIndexPath(indexPath) as? PickerCell) {
            pickerCell.deselectCell()
        }
    }
    
    /**
    * Ad Delegate - bring the banner on screen when it has an ad to display, move off when it doesn't
    */
    
    var bannerStarts : [ADBannerView : CGPoint] = [:]
    
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        if bannerStarts[banner] == nil || bannerStarts[banner] == banner.frame.origin {
            bannerStarts.updateValue(banner.frame.origin, forKey: banner)
            
            let height = banner.frame.height
            let newPosition = CGPointMake(banner.frame.origin.x, banner.frame.origin.y - height)
            UIView.animateWithDuration(1.0, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: nil, animations: {
                banner.frame.origin = newPosition
                }, completion: nil)
        }
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        if let start = bannerStarts[banner] {
            UIView.animateWithDuration(1.0, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: nil, animations: {
                banner.frame.origin = start
            }, completion: nil)
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