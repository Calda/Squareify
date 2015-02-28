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

let SQ_COLOR_DARK = UIColor(red: 43/256, green: 132/256, blue: 131/256, alpha: 1.0)
let SQ_COLOR_MEDIUM = UIColor(red: 56/256, green: 174/256, blue: 172/256, alpha: 1.0)
let SQ_COLOR_LIGHT = UIColor(red: 95/256, green: 205/256, blue: 204/256, alpha: 1.0)

class SquareifyController : UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, ADBannerViewDelegate, UIGestureRecognizerDelegate {
    
    let BACKGROUND_QUEUE = dispatch_queue_create("Background serial queue", DISPATCH_QUEUE_SERIAL)
    
    @IBOutlet weak var playerContainer: UIView!
    @IBOutlet weak var stillFrameViewer: UIImageView!
    @IBOutlet weak var nextBarButton: UIBarButtonItem!
    @IBOutlet weak var backBarButton: UIBarButtonItem!
    @IBOutlet weak var playerView: PlayerView!
    @IBOutlet weak var adBanner: ADBannerView!
    @IBOutlet weak var adPositionConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var pageContainer: UIView!
    @IBOutlet weak var pageContainerLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var noVideosMessage: UIView!
    
    @IBOutlet weak var pickerCollection: UICollectionView!
    @IBOutlet weak var pageConstraintBottomGuide: NSLayoutConstraint!
    @IBOutlet weak var pageConstraintBottomAd: NSLayoutConstraint!
    @IBOutlet weak var playerContainerPosition: NSLayoutConstraint!
    
    @IBOutlet weak var durationEditor: UIView!
    @IBOutlet weak var timelineView: UIView!
    var timelineHandles: (left: TimelineHandle, right: TimelineHandle)?
    @IBOutlet weak var durationDisplay: UILabel!
    @IBOutlet weak var instagramIcon: UIImageView!
    @IBOutlet weak var instagramTextPosition: NSLayoutConstraint!
    @IBOutlet weak var vineIcon: UIImageView!
    @IBOutlet weak var vineTextPosition: NSLayoutConstraint!
    
    var fetch : PHFetchResult?
    let imageManager = PHImageManager()
    var playerController : AVPlayerViewController?
    var playerMuted = true
    
    //will change for iPhone 4S support
    @IBOutlet weak var playerContainerAspectConstraint: NSLayoutConstraint!
    @IBOutlet weak var playerContainerMarginConstraint: NSLayoutConstraint!
    
    //the current view of the app
    enum SquareifyMode {
        case Picker, Duration
    }
    
    var currentMode : SquareifyMode = .Picker
    
    
    override func viewWillAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loopPlayerVideo", name: AVPlayerItemDidPlayToEndTimeNotification, object: nil) //set up video looping
        AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient, error: nil)
        
        let screenAspect = self.view.frame.width / self.view.frame.height
        if screenAspect > (9.5/16) { //is iPhone 4S
            playerContainerAspectConstraint.constant = -20
            playerContainerMarginConstraint.constant = -40
            playerView.REQUIRED_OFFEST = 95
            playerView.modifyOffsetBy(0, duration: 0, dampening: 1)
        }
        
        displayVideoThumbnails()
        //get photos auth
        
        
        if playerController?.player == nil {
            //only run this the first time the app is opened
            playerView.preferHeight(0, duration: 0, dampening: 1)
            
            //change title view
            let titleView = UILabel(frame: CGRectMake(0, 0, 100, 200))
            titleView.textAlignment = NSTextAlignment.Center
            titleView.text = "Choose a video"
            titleView.textColor = UIColor.whiteColor()
            titleView.font = UIFont(name: "STHeitiSC-Medium", size: 21)
            navigationItem.titleView = titleView
            
            let edgePanRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: "edgePanTrigger:")
            edgePanRecognizer.edges = .Left
            edgePanRecognizer.delegate = self
            self.view.addGestureRecognizer(edgePanRecognizer)
        }
        
    }
    
    
    override func viewDidAppear(animated: Bool) {
        if playerController?.player == nil {
            //only run this the first time the app is opened
            playerView.preferHeight(0, duration: 0, dampening: 1)
            
            
        }
        
        let authorization = PHPhotoLibrary.authorizationStatus()
        if authorization == PHAuthorizationStatus.NotDetermined {
            PHPhotoLibrary.requestAuthorization() { status in
                if status == PHAuthorizationStatus.Authorized {
                    self.displayVideoThumbnails()
                }
            }
        }
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
        if fetch == nil || fetch!.count == 0 {
            noVideosMessage.hidden = false
        }
        else {
            noVideosMessage.hidden = true
            self.automaticallyAdjustsScrollViewInsets = false
            pickerCollection.reloadData()
        }
    }
    
    //displays user selected video, unselects previous
    var currentSelected : NSIndexPath?
    
    func selectAndDisplay(selectionIndex: NSIndexPath) {
        //swap selected cell
        if let previousIndex = currentSelected {
            let previousCell = pickerCollection.cellForItemAtIndexPath(previousIndex) as PickerCell?
            previousCell?.deselectCell()
        } else { //this is the first video selected
            nextBarButton.enabled = true
        }
        
        let currentCell = pickerCollection.cellForItemAtIndexPath(selectionIndex) as PickerCell?
        if currentCell == nil {
            return
        }
        currentCell!.selectCell()
        currentSelected = selectionIndex
        
        //get current frame of current video
        if playerController?.player != nil {
            playerController!.player.pause()
            stillFrameViewer.image = self.getImageFromCurrentSelectionAtTime(playerController!.player.currentTime(), exact: true)
            stillFrameViewer.alpha = 1
        }
        
        if playerView.actualHeight == 0 {
            //expand player view
            let contentHeight = getPreferedContentHeight()
            playerView.preferContentHeight(getPreferedContentHeight(), navbar: navBarHeight(), duration: 0.45, dampening: 0.75)
        } else {
            playerContainerPosition.constant = -playerContainer.frame.width
            view.layoutIfNeeded()
        }
        
        //move selection to center of new frame
        let cellHeight = currentCell!.frame.height
        let scrollTo = currentCell!.frame.origin.y - cellHeight/2
        let scrollToClamped = min(max(0, scrollTo), pickerCollection.contentSize.height - pickerCollection.frame.height)
        let offset = CGPointMake(0, scrollToClamped)
        UIView.animateWithDuration(0.45, animations: {
            self.pickerCollection.contentOffset = offset
        })
        
        //get asset for new video
        let index = selectionIndex.indexAtPosition(1)
        if let asset = fetch?.objectAtIndex(index) as? PHAsset {
            imageManager.requestAVAssetForVideo(asset, options: nil, resultHandler: { video, audio, info in
                self.playerController?.videoGravity = "AVLayerVideoGravityResizeAspectFill"
                self.playerController?.player = AVPlayer(playerItem: AVPlayerItem(asset: video))
                self.playerController?.player.play()
                self.playerController?.player.volume = (self.playerMuted ? 0 : 1)
            })
            //animate in player

            playerContainerPosition.constant = 0
            UIView.animateWithDuration(1.0, delay: 0.25, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: nil, animations: {
                    self.view.layoutIfNeeded()
            }, completion: nil)
            
        }
    }

    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //setup embeded viewer
        if segue.identifier? == "embedViewer" {
            playerController = (segue.destinationViewController as AVPlayerViewController)
            playerView.givePlayerController(playerController!)
        }
    }
    
    
    @IBAction func toggleMute(sender: UIButton) {
        playerMuted = !playerMuted
        AVAudioSession.sharedInstance().setCategory(playerMuted ? AVAudioSessionCategoryAmbient : AVAudioSessionCategoryPlayback, error: nil)
        sender.setImage(UIImage(named: (playerMuted ? "unmute-filled" : "mute")), forState: UIControlState.Normal)
        if let player = playerController?.player? {
            player.volume = playerMuted ? 0 : 1
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
        let gutterSize = 1
        let screenWidth = view.frame.width
        let countPerRow = (screenWidth > 350 ? 4 : 3) //show 3 videos per row on 5s and 4s
        let avaliableWidth = screenWidth - CGFloat((countPerRow - 1) * gutterSize)
        let widthPerView = avaliableWidth / CGFloat(countPerRow)
        return CGSize(width: widthPerView, height: widthPerView)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.selectAndDisplay(indexPath)
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        if let pickerCell = (pickerCollection.cellForItemAtIndexPath(indexPath) as? PickerCell) {
            pickerCell.deselectCell()
        }
    }
    
    
    var playerAttachedToGesture = false
    @IBAction func pickedPanned(sender: UIPanGestureRecognizer) {
        let touchY = sender.locationInView(playerView).y
        if touchY < playerView.frame.height || playerAttachedToGesture {
            playerView.preferHeight(touchY, duration: 0, dampening: 1)
            pickerCollection.scrollEnabled = false
            playerAttachedToGesture = true
            playerController?.player?.pause()
        }
        if sender.state == .Ended && playerAttachedToGesture{
            pickerCollection.scrollEnabled = true
            playerAttachedToGesture = false
            //animate player moving to new resting state
            let velocity = sender.velocityInView(playerView).y
            //curve duration based on final velocity
            let duration = 1 - (0.7 - pow(1.5, -abs(velocity)/200))
            if velocity < 0 { //was being moved up
                playerView.preferHeight(0, duration: Double(duration), dampening: 1)
            } else {
                playerView.preferContentHeight(getPreferedContentHeight(), navbar: navBarHeight(), duration: Double(duration), dampening: 1)
                playerController?.player?.play()
            }
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
        changeViewTitleTo("Trim Clip", duration: 0.45)
        prepareDurationEditor()
        
        nextBarButton.enabled = false
        UIView.animateWithDuration(0.45, animations: {
            self.backBarButton.tintColor = self.nextBarButton.tintColor
        })
        backBarButton.enabled = true
        
        pageContainerLeftConstraint.constant = -view.frame.width
        UIView.animateWithDuration(0.45, animations: {
                self.view.layoutIfNeeded()
            })
        
        playerView.preferContentHeight(getPreferedContentHeight(), navbar: navBarHeight(), duration: 0.45, dampening: 0.8)
        playerController?.player?.play()
    }
    
    
    @IBAction func backButtonPressed(sender: AnyObject?) {
        if currentMode == .Picker {
            return //cannot go back from picker
        }
        changeViewTitleTo("Choose a video", duration: 0.45)
        currentMode = .Picker
        
        backBarButton.enabled = false
        UIView.animateWithDuration(0.45, animations: {
            self.backBarButton.tintColor = UIColor.clearColor()
        })
        nextBarButton.enabled = true
        
        pageContainerLeftConstraint.constant = 0
        UIView.animateWithDuration(0.45, animations: {
            self.view.layoutIfNeeded()
        })
        
        playerView.preferHeight(0, duration: 0.45, dampening: 1)
        playerController?.player?.pause()
    }

    
    func edgePanTrigger(sender: UIScreenEdgePanGestureRecognizer) {
        if currentMode == .Duration {
            //keep edge pan from working when on top of timeline
            if sender.state == UIGestureRecognizerState.Began {
                let panLocation = sender.locationInView(durationEditor)
                let zoneTop = timelineView.frame.origin.y - 20
                let zoneBottom = timelineView.frame.origin.y + timelineView.frame.height + 20
                let allowEdgePan = !(panLocation.y > zoneTop && panLocation.y < zoneBottom)
                if allowEdgePan {
                    backButtonPressed(sender)
                }
            }
        }
    }
    
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    
    func getPreferedContentHeight() -> CGFloat {
        if currentMode == .Duration {
            return timelineView.frame.origin.y + timelineView.frame.height + 20
        }
        //else if currentMode == .Picker {
        return view.frame.width * 0.6
        //}
    }
    
    
    func navBarHeight() -> CGFloat {
        return navigationController!.navigationBar.frame.height + 20
        //+20 accounts for time bar
    }
    
    
    /**
    * Prepare Duration Editor
    */
    
    func prepareDurationEditor() {
        updateDurationDisplays(currentAsset()!.duration)
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
            self.applyRoundedMask(view: imageView, cornerRadii: 0, corners: UIRectCorner.allZeros)
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
                        //bring handles' nonSelectionView to front of timeline after images are presented
                        if let (right, left) = self.timelineHandles? {
                            right.addNonSelectionView()
                            left.addNonSelectionView()
                        }
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
            self.applyRoundedMask(view: self.durationDisplay, cornerRadii: 15, corners: UIRectCorner.AllCorners)
            
            let handleHeight = timelineView.frame.height + 10
            let handleWidth = CGFloat(10)
            let handleY = timelineView.frame.origin.y - 5
            
            let leftFrame = CGRectMake(timelineView.frame.origin.x, handleY, handleWidth, handleHeight)
            let leftHandle = TimelineHandle(frame: leftFrame, timeline: timelineView)
            let rightFrame = CGRectMake(timelineView.frame.origin.x + timelineView.frame.width - handleWidth , handleY, handleWidth, handleHeight)
            let rightHandle = TimelineHandle(frame: rightFrame, timeline: timelineView)
            leftHandle.alpha = 0
            rightHandle.alpha = 0
            timelineHandles = (left: leftHandle, right: rightHandle)
            
            //set up constraint functions
            leftHandle.xMax = {
                return rightHandle.frame.origin.x - 15
            }
            leftHandle.nonSelectionRect = {
                //select area to left of handle
                let width = leftHandle.frame.origin.x - self.timelineView.frame.origin.x
                return CGRectMake(0, 0, width, self.timelineView.frame.height)
            }
            
            rightHandle.xMin = {
                return leftHandle.frame.origin.x + 15
            }
            rightHandle.xMax = {
                return self.timelineView.frame.origin.x + self.timelineView.frame.width - handleWidth
            }
            rightHandle.nonSelectionRect = {
                //select area to right of handle
                let width = (self.timelineView.frame.origin.x + self.timelineView.frame.width) - rightHandle.frame.origin.x + handleWidth
                return CGRectMake(rightHandle.frame.origin.x - handleWidth/2, 0, width, self.timelineView.frame.height)
            }
            
            for handle in [leftHandle, rightHandle] {
                handle.backgroundColor = SQ_COLOR_MEDIUM
                applyRoundedMask(view: handle, cornerRadii: 10, corners: .AllCorners)
                durationEditor.addSubview(handle)
            }
        }
        //reset handles
        else {
            let (leftHandle, rightHandle) = timelineHandles!
            for handle in [leftHandle, rightHandle] {
                handle.alpha = 0
                handle.nonSelectionView.alpha = 0
            }
            leftHandle.updatePosition(leftHandle.xMin())
            rightHandle.updatePosition(rightHandle.xMax())
        }
    }
    
    
    /**
    * Duration Editor use functions
    */
    
    var grabbedHandle : TimelineHandle?
    
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
                if grabbedHandle != nil {
                    playerController!.player.pause()
                }
            }
        }
        
        if let handle = grabbedHandle {
            handle.updatePosition(panLoc.x)
            let (startTime, endTime, range) = getSelectionRange()
            let seekTime = (grabbedHandle == timelineHandles!.left ? startTime : endTime)
            playerController!.player.seekToTime(seekTime, toleranceBefore: CMTimeMake(1,10), toleranceAfter: CMTimeMake(1,10))
            updateDurationDisplays(range.duration)
        }
        
        if pan.state == .Ended {
            playerController!.player.play()
            if grabbedHandle == timelineHandles!.right {
                playerController!.player.seekToTime(getSelectionRange().start, toleranceBefore: CMTimeMake(1,10), toleranceAfter: CMTimeMake(1,10))
                startCustomEndListener()
            }
            grabbedHandle = nil
        }
    }
    
    
    func getSelectionRange() -> (start: CMTime, end: CMTime, range: CMTimeRange) {
        let assetDuration = currentAsset()!.duration
        
        func percentageToTime(percent: CGFloat) -> CMTime {
            let seconds = CMTimeGetSeconds(assetDuration) * Float64(percent)
            return CMTimeMakeWithSeconds(seconds, assetDuration.timescale)
        }
        
        if self.currentMode == .Duration {
            if let (left, right) = timelineHandles {
                let selectionLeft = left.frame.origin.x - timelineView.frame.origin.x
                let selectionRight = (right.frame.origin.x + right.frame.width) - timelineView.frame.origin.x
                let startTime = percentageToTime(selectionLeft / timelineView.frame.width)
                let endTime = percentageToTime(selectionRight / timelineView.frame.width)
                let duration = CMTimeRangeMake(startTime, CMTimeSubtract(endTime, startTime))
                return (start: startTime, end: endTime, range: duration)
            }
        }
        
        return (start: kCMTimeZero, end: assetDuration, range: CMTimeRangeMake(kCMTimeZero, assetDuration))
    }
    
    
    func updateDurationDisplays(duration: CMTime) {
        self.durationDisplay.text = self.timeToDecoratedString(duration)
        let durationSeconds = CMTimeGetSeconds(duration)
        
        func durationAllowed(image: UIImageView, constraint: NSLayoutConstraint) {
            if image.alpha != 1 { //image needs animation change
                image.alpha = 1
                constraint.constant -= 40
                UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: nil, animations: {
                    self.view.layoutIfNeeded()
                }, completion: nil)
            }
        }
        
        func durationNotAllowed(image: UIImageView, constraint: NSLayoutConstraint) {
            if image.alpha == 1 { //image needs animation change
                image.alpha = 0.45
                constraint.constant += 40
                UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: nil, animations: {
                    self.view.layoutIfNeeded()
                }, completion: nil)
            }
        }
        
        if durationSeconds > 15.0 {
            durationNotAllowed(instagramIcon, instagramTextPosition)
        } else {
            durationAllowed(instagramIcon, instagramTextPosition)
        }
        
        if durationSeconds > 6.0 {
            durationNotAllowed(vineIcon, vineTextPosition)
        } else {
            durationAllowed(vineIcon, vineTextPosition)
        }
        
    }
    
    
    /**
    * Ad Delegate - bring the banner on screen when it has an ad to display, move off when it doesn't
    */
    
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        if adPositionConstraint.constant == -50 { //ad is off-screen
            adPositionConstraint.constant = 0
            UIView.animateWithDuration(0.5, animations: {
                    self.view.layoutIfNeeded()
            })
            playerView.modifyOffsetBy(50, duration: 0.5, dampening: 1)
        }
    }
    
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        if adPositionConstraint.constant == 0 { //ad is on-screen
            adPositionConstraint.constant = -50
            UIView.animateWithDuration(0.5, animations: {
                    self.view.layoutIfNeeded()
            })
            playerView.modifyOffsetBy(-50, duration: 0.5, dampening: 1)
        }
    }
    
    
    /**
    * Utility Functions
    */
    
    //retreive images from videos
    func getImageFromCurrentSelectionAtTime(time: CMTime, exact: Bool) -> UIImage? {
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
    
    
    func timeToDecoratedString(time: CMTime) -> String {
        let timeInSeconds = CMTimeGetSeconds(time) + Float64(0.1)
        let minutes = Int(timeInSeconds) / 60
        let seconds = Int(timeInSeconds) % 60
        if minutes > 0 {
            let secondsString = (seconds < 10 ? "0" : "") + "\(seconds)"
            return "\(minutes):\(secondsString)"
        }
        else {
            let tenths = Int(timeInSeconds * 10) % 10
            return "\(seconds).\(tenths)"
        }
    }
    
    
    //called when video ends, if the view is on screen
    func loopPlayerVideo() {
        if self.isViewLoaded() && self.view.window != nil {
            playerController?.player.seekToTime(self.getSelectionRange().start, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
            playerController?.player.play()
        }
    }
    
    
    var customListenerInProgress = false
    func startCustomEndListener() {
        if !customListenerInProgress {
            customListenerInProgress = true
            customEndListener()
        }
    }
    
    
    func customEndListener() {
        if let currentTime = playerController?.player?.currentTime() {
            let endTime = self.getSelectionRange().end
            if CMTimeGetSeconds(currentTime) > CMTimeGetSeconds(endTime) {
                loopPlayerVideo()
            }
            let endTimeSeconds = CMTimeGetSeconds(endTime)
            if CMTimeCompare(currentAsset()!.duration, endTime) != 0 { //times are not equal
                delay(0.1, closure: {
                    self.customEndListener()
                })
            } else {
                customListenerInProgress = false
            }
        }
        
    }
    
    
    func delay(delay:Double, closure:()->()) {
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
        dispatch_after(time, dispatch_get_main_queue(), closure)
    }

    
}