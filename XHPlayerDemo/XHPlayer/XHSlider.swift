//
//  XHSlider.swift
//  XHPlayerDemo
//
//  Created by 李鑫浩 on 2017/10/19.
//  Copyright © 2017年 allens. All rights reserved.
//

import UIKit

class XHSlider: UISlider {

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:- Override Super method
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        super.trackRect(forBounds: bounds)
        return CGRect(x: bounds.origin.x + 6, y: (bounds.size.height - 3) / 2.0, width: bounds.size.width - 12, height: 3)
    }
    
    override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        let newRect = CGRect(x: rect.origin.x - 6, y: rect.origin.y, width: rect.size.width + 12, height: rect.size.height)
        let result = super.thumbRect(forBounds: bounds, trackRect: newRect, value: value)
        return result
    }
    
    //MARK:- Private method
    func setup() -> Void {
        let image = XHPlayerCommon.imageWithName("player_progress_flag")
        self.setThumbImage(image, for: .normal)
        self.setThumbImage(image, for: .highlighted)
    }
}
