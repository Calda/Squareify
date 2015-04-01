
//
//  ColorCollection.swift
//  Squareify
//
//  Created by DFA Film 9: K-9 on 4/1/15.
//  Copyright (c) 2015 Cal. All rights reserved.
//

import Foundation
import UIKit

class ColorCollection : UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collection: UICollectionView!
    var colorConfig : [String] = []
    
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
    }
    
    
    func colorsFromHexString(hex:String) -> (background: UIColor, text: UIColor) {
        let nsString = hex as NSString
        var rString = nsString.substringToIndex(2)
        var gString = (nsString.substringFromIndex(2) as NSString).substringToIndex(2)
        var bString = (nsString.substringFromIndex(4) as NSString).substringToIndex(2)
        
        var r:CUnsignedInt = 0, g:CUnsignedInt = 0, b:CUnsignedInt = 0;
        NSScanner(string: rString).scanHexInt(&r)
        NSScanner(string: gString).scanHexInt(&g)
        NSScanner(string: bString).scanHexInt(&b)
        
        let background = UIColor(red: CGFloat(r) / CGFloat(255.0), green: CGFloat(g) / CGFloat(255.0), blue: CGFloat(b) / CGFloat(255.0), alpha: 1.0)
        var text : UIColor
        
        //background.getHue(h, saturation: s, brightness: b, alpha: nil)
        
        let average = (r + g + b) / 3
        if average > CUnsignedInt(220) { //black text
            text = UIColor(hue: 0, saturation: 0, brightness: 0.05, alpha: 1.0)
        } else { //white text
            text = UIColor(hue: 0, saturation: 0, brightness: 1.0, alpha: 1.0)
        }
        return (background, text)
    }
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colorConfig.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("color", forIndexPath: indexPath) as ColorCell
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
        let (background, text) = colorsFromHexString(hex)
        cell.name.text = name
        cell.name.textColor = text
        cell.backgroundColor = background
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
        return CGSizeMake(100, 100)
    }
    
}

class ColorCell : UICollectionViewCell {
    
    @IBOutlet weak var name: UILabel!
    
}