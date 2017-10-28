//
//  XHPlayerCommon.swift
//  XHPlayerDemo
//
//  Created by 李鑫浩 on 2017/10/19.
//  Copyright © 2017年 allens. All rights reserved.
//

import UIKit

public class XHPlayerCommon: NSObject {
    
    //查看APP是否支持某个方向
    public class func supportOrientation(_ orientation : UIDeviceOrientation) -> Bool {
        let dictionary = Bundle.main.infoDictionary
        let orientations : NSArray = dictionary!["UISupportedInterfaceOrientations"] as! NSArray
        if orientation == .landscapeLeft {
            return orientations.contains("UIInterfaceOrientationLandscapeLeft")
        } else if orientation == .landscapeRight {
            return orientations.contains("UIInterfaceOrientationLandscapeRight")
        } else if orientation == .portrait {
            return orientations.contains("UIInterfaceOrientationPortrait")
        } else if orientation == .portraitUpsideDown {
            return orientations.contains("UIInterfaceOrientationPortraitUpsideDown")
        } else {
            return false
        }
    }
    
    //读取图片
    public class func imageWithName(_ imageName : NSString) -> UIImage {
        let bundle = Bundle.init(path: Bundle.main.path(forResource: "XHPlayer", ofType: "bundle")!)
        let path = bundle?.path(forResource: imageName as String, ofType: "png")
        return UIImage.init(contentsOfFile: path!)!
    }
    
    //将时间戳转为 00:00 形式
    public class func timeStringWithDuration (_ duration : CGFloat) -> NSString {
        let hour = NSInteger(duration) / 3600
        let minute =  String(format:"%02d", NSInteger(duration) % 3600 / 60)
        let seconds = String(format:"%02d", NSInteger(duration) % 60)
        let result = NSMutableString()
        if hour > 0  {
            result.append(String(format:"%02d", hour) + ":")
        }
        result.append(minute + ":")
        result.append(seconds)
        return result
    }
    
    //获取有行高的属性字符串
    public class func attributedStringWithSpaceHeight(_ text : NSString , _ spaceHeight : CGFloat) -> NSMutableAttributedString {
        let attributedString = NSMutableAttributedString.init(string: text as String)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = spaceHeight
        attributedString.addAttribute(NSAttributedStringKey.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, text.length))
        return attributedString
    }
    
}















