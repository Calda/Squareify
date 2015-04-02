
//
//  ColorCollection.swift
//  Squareify
//
//  Created by DFA Film 9: K-9 on 4/1/15.
//  Copyright (c) 2015 Cal. All rights reserved.
//

import Foundation
import UIKit

let SQColorNotification : String = "SQColorNotification"

class ColorCollection : UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collection: UICollectionView!
    @IBOutlet weak var handle: UIView!
    var colorConfig : [String] = []
    var currentSelection : UIColor = UIColor.darkGrayColor()
    
    override func viewWillAppear(animated: Bool) {
        let bundle = NSBundle.mainBundle()
        let path = bundle.pathForResource("colors", ofType: "txt")
        var err: NSError? = NSError()
        let content = String(contentsOfFile: path!, encoding: NSUTF8StringEncoding, error: &err)
        colorConfig = content!.componentsSeparatedByString("\n")
        /*for config in strings!{
            //format: HEXHEX Color Name
            let splits = split(config) {$0 == " "}
            let hex = splits[0]
            var name = ""
            for i in 1..<(splits.count) {
                name += splits[i]
                if i != splits.count - 1 {
                    name += " "
                }
            }
            colors.append(hex, name)
        }*/
        collection.reloadData()
        handle.layer.cornerRadius = 4
        handle.clipsToBounds = true
    }
    
    
    func colorsFromHexString(hex:String) -> (background: UIColor, text: UIColor, border: UIColor) {
        let nsString = hex as NSString
        var rString = nsString.substringToIndex(2)
        var gString = (nsString.substringFromIndex(2) as NSString).substringToIndex(2)
        var bString = (nsString.substringFromIndex(4) as NSString).substringToIndex(2)
        
        var r:CUnsignedInt = 0, g:CUnsignedInt = 0, b:CUnsignedInt = 0;
        NSScanner(string: rString).scanHexInt(&r)
        NSScanner(string: gString).scanHexInt(&g)
        NSScanner(string: bString).scanHexInt(&b)
        let background = UIColor(red: CGFloat(r) / CGFloat(255.0), green: CGFloat(g) / CGFloat(255.0), blue: CGFloat(b) / CGFloat(255.0), alpha: 1.0)
        
        func colorLuma(color: UIColor) -> CGFloat{
            var r : CGFloat  = 0.0
            var g : CGFloat  = 0.0
            var b : CGFloat  = 0.0
            color.getRed(&r, green: &g, blue: &b, alpha: nil)
            let lumaR : CGFloat = CGFloat(r) * 0.3
            let lumaG : CGFloat = CGFloat(g) * 0.59
            let lumaB : CGFloat = CGFloat(b) * 0.11
            return (lumaR + lumaG + lumaB) / 3
        }
        
        var hue : CGFloat  = 0.0
        var sat : CGFloat  = 0.0
        var bright : CGFloat  = 0.0
        background.getHue(&hue, saturation: &sat, brightness: &bright, alpha: nil)
        let backgroundLuma = colorLuma(background)

        var text = UIColor(hue: hue, saturation: sat, brightness: bright + 0.35, alpha: 1.0)
        let textLuma = colorLuma(text)
        let lumaDiff = abs(textLuma - backgroundLuma)
        if lumaDiff < 0.05 {
            text = UIColor(hue: hue, saturation: sat, brightness: bright - 0.35, alpha: 1.0)
        }
        
        let border = UIColor(hue: hue, saturation: sat, brightness: bright - 0.1, alpha: 1.0)
        
        return (background, text, border)
    }
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colorConfig.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var identifier = ""
        if indexPath.item % 2 == 0 { identifier = "color_top" }
        else { identifier = "color_bottom" }
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath) as ColorCell
        let configString = colorConfig[indexPath.item]
        let splits = split(configString) {$0 == " "}
        let hex = splits[0]
        var name = ""
        for i in 1..<(splits.count) {
            name += splits[i]
            if i != splits.count - 1 {
                name += " "
            }
        }
        let (background, text, border) = colorsFromHexString(hex)
        cell.name.text = name
        cell.name.textColor = text
        cell.color.backgroundColor = background
        cell.addBorderOfColor(border)

        if CGColorEqualToColor(currentSelection.CGColor, background.CGColor) {
            cell.animateSelection()
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(95, 100)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? ColorCell {
            let color = cell.color.backgroundColor!
            if !CGColorEqualToColor(currentSelection.CGColor, color.CGColor) {
                cell.animateSelection()
                currentSelection = color
                NSNotificationCenter.defaultCenter().postNotificationName(SQColorNotification, object: color)
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? ColorCell {
            cell.animateUnselection()
        }
    }
    
}

class ColorCell : UICollectionViewCell {
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var color: UILabel!
    
    func addBorderOfColor(borderColor: UIColor) {
        color.layer.cornerRadius = 15
        color.layer.borderWidth = 2
        color.layer.borderColor = borderColor.CGColor
        color.clipsToBounds = true
    }
    
    func animateSelection() {
        let transform = CATransform3DGetAffineTransform(self.layer.transform)
        let newTransform = CGAffineTransformScale(transform, 0.75, 0.75)
        let new3D = CATransform3DMakeAffineTransform(newTransform)
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 10, options: nil, animations: {
            self.layer.transform = new3D
        }, completion: nil)
    }
    
    func animateUnselection() {
        let transform = CATransform3DGetAffineTransform(self.layer.transform)
        let newTransform = CGAffineTransformScale(transform, 4/3, 4/3)
        let new3D = CATransform3DMakeAffineTransform(newTransform)
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 10, options: nil, animations: {
            self.layer.transform = new3D
        }, completion: nil)
    }
    
}