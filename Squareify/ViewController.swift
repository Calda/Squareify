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

class ViewController: UIViewController {

    @IBOutlet weak var movingSquare: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        for touch in touches {
            updateSelectionPosition((touch as UITouch).locationInView(self.view).y)
            break
        }
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        for touch in touches {
            updateSelectionPosition((touch as UITouch).locationInView(self.view).y)
            break
        }
    }
    
    func updateSelectionPosition(y : CGFloat) {
        let frameHeight = movingSquare.frame.size.height
        let squareHeight = frameHeight / 3
        let screenHeight = self.view.frame.height
        var newY = y - frameHeight / 2
        
        //keep center square from going off top of screen
        if newY < -squareHeight {
            newY = -squareHeight
        }
        
        //keep center square from going off bottom of screen
        if newY > -(2 * squareHeight - screenHeight) {
            newY = -(2 * squareHeight - screenHeight)
        }
        
        movingSquare.frame.origin.y = newY
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier? == "showMovie" {
            let playerController = segue.destinationViewController as AVPlayerViewController
            playerController.player = AVPlayer(URL: NSBundle.mainBundle().URLForResource("testvideo", withExtension: "mov"))
        }
    }
}

