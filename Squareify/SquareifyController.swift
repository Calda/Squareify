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

class SquareifyController : UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, ADBannerViewDelegate, UIGestureRecognizerDelegate {
    
    let BACKGROUND_QUEUE = dispatch_queue_create("Background serial queue", DISPATCH_QUEUE_SERIAL)
    let COLOR_DARK = UIColor(red: 43/256, green: 132/256, blue: 131/256, alpha: 1.0)
    let COLOR_MEDIUM = UIColor(red: 56/256, green: 174/256, blue: 172/256, alpha: 1.0)
    let COLOR_LIGHT = UIColor(red: 95/256, green: 205/256, blue: 204/256, alpha: 1.0)
    
    @IBOutlet weak var playerContainer: UIView!
    @IBOutlet weak var stillFrameViewer: UIImageView!
    @IBOutlet weak var welcomeView: UIView!
    @IBOutlet weak var nextBarButton: UIBarButtonItem!
    @IBOutlet weak var backBarButton: UIBarButtonItem!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var styleArrow: UIImageView!
    @IBOutlet weak var adBanner: ADBannerView!
    
    @IBOutlet weak var pickerCollection: UICollectionView!
    
    @IBOutlet weak var durationEditor: UIView!
    @IBOutlet weak var timelineView: UIView!
    var timelineHandles: (left: UIView, right: UIView)?
    
    var fetch : PHFetchResult?
    let imageManager = PHImageManager()
    var playerController : AVPlayerViewController?
    
    //will change for iPhone 4S support
    @IBOutlet weak var playerViewAspectConstraint: NSLayoutConstraint!
    @IBOutlet weak var welcomeText: UILabel!
    @IBOutlet weak var playerContainerAspectConstraint: NSLayoutConstraint!
    @IBOutlet weak var playerContainerMarginConstraint: NSLayoutConstraint!
    
    //original configuations for items that will animate
    var originalPlayerPosition : CGPoint?
    var originalStillViewerPosition : CGPoint?
    var originalArrowPosition : CGPoint?
    var originalDurationEditorPosition : CGPoint?
    var originalPickerPosition : CGPoint?
    var originalTimelineFrame : CGRect?
    
    //the current view of the app
    enum SquareifyMode {
        case Picker, Duration
    }
    
    var currentMode : SquareifyMode = .Picker
    
    
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
        originalDurationEditorPosition = CGPointMake(self.view.frame.width, durationEditor.frame.origin.y)
        durationEditor.frame.origin = originalDurationEditorPosition!
        originalPickerPosition = pickerCollection.frame.origin
        originalTimelineFrame = timelineView.frame
        
        //add gesture recognizer
        let edgePanRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: "edgePanTrigger:")
        edgePanRecognizer.edges = .Left
        self.view.addGestureRecognizer(edgePanRecognizer)
        
        //change title view
        let titleView = UILabel(frame: CGRectMake(0, 0, 100, 200))
        titleView.textAlignment = NSTextAlignment.Center
        titleView.text = "Squareify"
        titleView.textColor = UIColor.whiteColor()
        titleView.font = UIFont(name: "STHeitiSC-Medium", size: 21)
        navigationItem.titleView = titleView
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
            stillFrameViewer.image = self.getImageFromCurrentSelectionAtTime(playerController!.player.currentTime(), exact: true)
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
        if currentMode == .Duration {
            return //cannot go forward from Duration Editor yet
        }
        currentMode = .Duration
        changeViewTitleTo("Trim Clip", duration: 0.5)
        prepareDurationEditor()
        let newPickerOrigin = CGPointMake(-self.view.frame.width * 2, pickerCollection.frame.origin.y)
        UIView.animateWithDuration(1.0, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: nil, animations: {
                self.pickerCollection.frame.origin = newPickerOrigin
            }, completion: { success in
                if self.currentMode != .Picker {
                    self.pickerCollection.hidden = true
                }
        })
        durationEditor.frame.origin = originalDurationEditorPosition!
        durationEditor.hidden = false
        UIView.animateWithDuration(1.0, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: nil, animations: {
                self.durationEditor.frame.origin = self.originalPickerPosition!
            }, completion: nil)
        
        nextBarButton.enabled = false
        UIView.animateWithDuration(0.5, animations: {
            self.backBarButton.tintColor = self.nextBarButton.tintColor
        })
        backBarButton.enabled = true
    }
    
    
    @IBAction func backButtonPressed(sender: AnyObject?) {
        if currentMode == .Picker {
            return //cannot go back from picker
        }
        changeViewTitleTo("Squareify", duration: 0.5)
        currentMode = .Picker
        pickerCollection.frame.origin = CGPointMake(-self.view.frame.width * 2, pickerCollection.frame.origin.y)
        pickerCollection.hidden = false
        UIView.animateWithDuration(1.0, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: nil, animations: {
            self.pickerCollection.frame.origin = self.originalPickerPosition!
            }, completion: nil)
        UIView.animateWithDuration(1.0, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: nil, animations: {
                self.durationEditor.frame.origin = self.originalDurationEditorPosition!
            }, completion: { success in
                if self.currentMode != .Duration {
                    self.durationEditor.hidden = true
                }
        })
        backBarButton.enabled = false
        UIView.animateWithDuration(0.5, animations: {
            self.backBarButton.tintColor = UIColor.clearColor()
        })
        nextBarButton.enabled = true
    }
    
    
    func edgePanTrigger(sender: UIScreenEdgePanGestureRecognizer) {
        if currentMode == .Duration {
            //keep edge pan from working when on top of timeline
            let panLocation = sender.locationInView(durationEditor)
            let zoneTop = timelineView.frame.origin.y - 20
            let zoneBottom = timelineView.frame.origin.y + timelineView.frame.height + 20
            let allowEdgePan = !(panLocation.y > zoneTop && panLocation.y < zoneBottom)
            if allowEdgePan {
                backButtonPressed(sender)
            }
        }
    }
    
    
    /**
    * Prepare Duration Editor
    */
    
    func prepareDurationEditor() {
        resetTimelineControls()
        populateTimelineView()
    }
    
    
    func populateTimelineView() {
        //erase any previous stills
        for subview in timelineView.subviews {
            if let imageView = subview as? UIImageView {
                imageView.removeFromSuperview()
            }
        }
        
        //generate new stills
        let width = timelineView.frame.width
        let height = timelineView.frame.height
        let assetTrack = currentAssetTrack()!
        let firstFrameImage = self.getImageFromCurrentSelectionAtTime(kCMTimeZero, exact: false)!

        let frameSize = firstFrameImage.size
        let frameAspect = frameSize.width / frameSize.height
        let frameWidthOnTimeline = frameAspect * height
        let numberOfFramesOnTimeline: Int = Int(ceil(width / (frameWidthOnTimeline + 1))) //+1 for gutter
        let durationPerFrame = CMTimeGetSeconds(assetTrack.timeRange.duration) / Float64(numberOfFramesOnTimeline)
        generateAndAddFrames(numberOfFramesOnTimeline, width: frameWidthOnTimeline, height: height, durationPerFrame: durationPerFrame)
    
        applyRoundedMask(view: timelineView, cornerRadii: 10, corners: .AllCorners)
    }
    
    
    func generateAndAddFrames(count: Int, width: CGFloat, height: CGFloat, durationPerFrame: Float64) {
        for frame in 0...(count - 1) {
            let size = CGSizeMake(width, height)
            let origin = CGPointMake((width + 1) * CGFloat(frame), 0) //+  adds gutter
            let imageView = UIImageView(frame: CGRect(origin: origin, size: size))
            imageView.contentMode = UIViewContentMode.ScaleAspectFit
            let frameTime = CMTimeMakeWithSeconds(durationPerFrame * Float64(frame), 1000)
            dispatch_async(BACKGROUND_QUEUE, {
                //grab frame
                let image = self.getImageFromCurrentSelectionAtTime(frameTime, exact: true)
                UIGraphicsBeginImageContext(CGSizeMake(1,1))
                let context = UIGraphicsGetCurrentContext()
                CGContextDrawImage(context, CGRectMake(0,0,1,1), image!.CGImage)
                UIGraphicsEndImageContext()
                //animate in new frame
                dispatch_sync(dispatch_get_main_queue(), {
                    imageView.image = image
                    let animateFinal = imageView.frame.origin
                    let animateStart = CGPointMake(animateFinal.x - 100, animateFinal.y)
                    imageView.frame.origin = animateStart
                    imageView.alpha = 0
                    UIView.animateWithDuration(0.75, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: nil, animations: {
                        imageView.frame.origin = animateFinal
                        imageView.alpha = 1
                        }, completion: nil)
                    //animate in handles when left image in on screen
                    if frame == count - 1 {
                        self.animateInHandles()
                    }
                })
            })
            self.timelineView.addSubview(imageView)
        }
    }
    
    
    func animateInHandles() {
        if let (right, left) = self.timelineHandles? {
            for handle in [right, left] {
                let originalPos = handle.frame.origin
                let startPos = CGPointMake(originalPos.x, originalPos.y + handle.frame.height)
                handle.frame.origin = startPos
                UIView.animateWithDuration(1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: nil, animations: {
                    handle.frame.origin = originalPos
                    handle.alpha = 1
                    }, completion: nil)
            }
        }
    }
    
    
    func resetTimelineControls() {
        //create handles
        if timelineHandles == nil { //is first time showing clip trimmer
            let handleHeight = timelineView.frame.height + 10
            let handleWidth = CGFloat(10)
            let handleY = timelineView.frame.origin.y - 5
            let leftHandle = UIView(frame: CGRectMake(timelineView.frame.origin.x, handleY, handleWidth, handleHeight))
            let rightHandle = UIView(frame: CGRectMake(timelineView.frame.origin.x + timelineView.frame.width - handleWidth , handleY, handleWidth, handleHeight))
            timelineHandles = (left: leftHandle, right: rightHandle)
            for handle in [leftHandle, rightHandle] {
                handle.backgroundColor = COLOR_MEDIUM
                applyRoundedMask(view: handle, cornerRadii: 10, corners: .AllCorners)
                durationEditor.addSubview(handle)
            }
        }
        //reset handles
        let (leftHandle, rightHandle) = timelineHandles!
        for handle in [leftHandle, rightHandle] {
            handle.alpha = 0
        }
    }
    
    
    /**
    * Duration Editor use functions
    */
    
    var grabbedHandle : UIView?
    
    @IBAction func durationEditorPanRecognized(pan: UIPanGestureRecognizer) {
        let panLoc = pan.locationInView(durationEditor)
        
        if pan.state == .Began {
            if let (leftHandle, rightHandle) = self.timelineHandles? {
                if self.isTouch(pan.locationInView(leftHandle), inView: leftHandle, withPadding: 25) {
                    grabbedHandle = leftHandle
                }
                else if self.isTouch(pan.locationInView(rightHandle), inView: rightHandle, withPadding: 25) {
                    grabbedHandle = rightHandle
                }
            }
        }
        
        if let handle = grabbedHandle {
            handle.frame.origin = CGPointMake(panLoc.x, handle.frame.origin.y)
        }
        
        if pan.state == .Ended {
            grabbedHandle = nil
        }
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
    
    
    /**
    * Utility Functions
    */
    
    //retreive images from videos
    func getImageFromCurrentSelectionAtTime(time: CMTime, exact: Bool) -> UIImage?{
        if let currentSelection = currentAsset() {
            let assetTrack = (currentSelection.tracksWithMediaType(AVMediaTypeVideo).first as AVAssetTrack)
            let transformedDims = CGSizeApplyAffineTransform(assetTrack.naturalSize, assetTrack.preferredTransform)
            //from experimentation, a negative width value in the transformed dims means the image will need to be rotated
            let orientation: UIImageOrientation = (transformedDims.width < 0 ? .Right : .Up)
            let generator = AVAssetImageGenerator(asset: currentSelection)
            if exact {
                generator.requestedTimeToleranceAfter = kCMTimeZero
                generator.requestedTimeToleranceBefore = kCMTimeZero
            }
            let requestedFrame = generator.copyCGImageAtTime(time, actualTime: nil, error: nil)
            let correctedFrame = UIImage(CGImage: requestedFrame, scale: 1.0, orientation: orientation)
            return correctedFrame
        }
        return nil
    }
    
    
    func currentAsset() -> AVAsset? {
        return playerController?.player?.currentItem?.asset
    }
    
    
    func currentAssetTrack() -> AVAssetTrack? {
        if let currentAsset = currentAsset() {
            return (currentAsset.tracksWithMediaType(AVMediaTypeVideo).first as AVAssetTrack)
        }
        return nil
    }
    
    
    func changeViewTitleTo(title: String, duration: NSTimeInterval) {
        if let titleView = self.navigationItem.titleView? as? UILabel {
            UIView.animateWithDuration(duration/2, animations: {
                titleView.alpha = 0
                }, completion: { success in
                    titleView.text = title
                    //for some reason this is the only way that would work
                    UIView.animateWithDuration(duration/2, animations: {
                        titleView.alpha = 1
                    })
            })
        }
    }
    
    
    func applyRoundedMask(#view: UIView, cornerRadii: CGFloat, corners: UIRectCorner) {
        let shape = CAShapeLayer()
        let mask = CGRect(origin: CGPointMake(0, 0), size: view.frame.size)
        shape.path = UIBezierPath(roundedRect: mask, byRoundingCorners: corners, cornerRadii: CGSizeMake(cornerRadii, cornerRadii)).CGPath
        view.layer.mask = shape
    }
    
    
    func isTouch(touch: CGPoint, inView view: UIView, withPadding padding: CGFloat) -> Bool {
        let paddedRect = CGRectMake(-padding, -padding, view.frame.width + 2 * padding, view.frame.height + 2 * padding)
        return CGRectContainsPoint(paddedRect, touch)
    }
    
}