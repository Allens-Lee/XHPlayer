//
//  XHViewController.swift
//  XHPlayerDemo
//
//  Created by 李鑫浩 on 2017/10/20.
//  Copyright © 2017年 allens. All rights reserved.
//

import UIKit

class XHViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    //改变状态栏颜色
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return UIStatusBarStyle.lightContent
    }
    
    /**
     * 默认所有都不支持转屏,如需个别页面支持除竖屏外的其他方向，请在viewController重新下边这三个方法
     */
    // 是否支持自动转屏
    override var shouldAutorotate: Bool {
        let dictionary = Bundle.main.infoDictionary
        let orientations : NSArray = dictionary!["UISupportedInterfaceOrientations"] as! NSArray
        if orientations.count == 1 {
            return false
        } else {
            return true
        }
    }
    
    // 支持哪些屏幕方向
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        let dictionary = Bundle.main.infoDictionary
        let orientations : NSArray = dictionary!["UISupportedInterfaceOrientations"] as! NSArray
        if orientations.count == 1 {
            return .portrait
        } else {
            return .all
        }
    }
    
    // 默认的屏幕方向（当前ViewController必须是通过模态出来的UIViewController（模态带导航的无效）方式展现出来的，才会调用这个方法）
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        let dictionary = Bundle.main.infoDictionary
        let orientations : NSArray = dictionary!["UISupportedInterfaceOrientations"] as! NSArray
        if orientations.count == 1 {
            return .portrait
        } else {
            return .unknown
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
