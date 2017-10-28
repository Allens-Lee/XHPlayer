//
//  XHTabBarController.swift
//  XHPlayerDemo
//
//  Created by 李鑫浩 on 2017/10/20.
//  Copyright © 2017年 allens. All rights reserved.
//

import UIKit

class XHTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    /**
     * 默认所有都不支持转屏,如需个别页面支持除竖屏外的其他方向，请在viewController重新下边这三个方法
     */
    // 是否支持自动转屏
    override var shouldAutorotate: Bool {
        let vcs = self.viewControllers
        if (vcs?.count)! > self.selectedIndex {
            let vc = self.viewControllers?[self.selectedIndex]
            if (vc?.isKind(of: UINavigationController.self))! {
                return (vc as! UINavigationController).shouldAutorotate
            } else {
                return (vc?.shouldAutorotate)!
            }
        }
        return false
    }
    
    // 支持哪些屏幕方向
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        let vcs = self.viewControllers
        if (vcs?.count)! > self.selectedIndex {
            let vc = self.viewControllers?[self.selectedIndex]
            if (vc?.isKind(of: UINavigationController.self))! {
                return (vc as! UINavigationController).supportedInterfaceOrientations
            } else {
                return (vc?.supportedInterfaceOrientations)!
            }
        }
        return UIInterfaceOrientationMask.portrait
    }

    // 默认的屏幕方向（当前ViewController必须是通过模态出来的UIViewController（模态带导航的无效）方式展现出来的，才会调用这个方法）
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        let vcs = self.viewControllers
        if (vcs?.count)! > self.selectedIndex {
            let vc = self.viewControllers?[self.selectedIndex]
            if (vc?.isKind(of: UINavigationController.self))! {
                return (vc as! UINavigationController).preferredInterfaceOrientationForPresentation
            } else {
                return (vc?.preferredInterfaceOrientationForPresentation)!
            }
        }
        return UIInterfaceOrientation.portrait
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
