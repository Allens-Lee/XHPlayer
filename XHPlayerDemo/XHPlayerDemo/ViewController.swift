//
//  ViewController.swift
//  XHPlayerDemo
//
//  Created by 李鑫浩 on 2017/10/18.
//  Copyright © 2017年 allens. All rights reserved.
//

import UIKit
import SnapKit

class ViewController: XHViewController {

    var player : XHPlayer!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "XHPlayer"
        
        player = XHPlayer()
        self.view.addSubview(player)
        
        player.snp.makeConstraints { (make) in
            make.left.right.equalTo(0)
            make.height.equalTo(200)
            make.centerY.equalTo(250)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        player.setAssetUrl("http://baobab.wdjcdn.com/1458715233692shouwang_x264.mp4")
        player.setPlayerTitle("守望先锋")
        player.backBlock = {() -> Void in
            print("返回了")
        }
        player.play()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

