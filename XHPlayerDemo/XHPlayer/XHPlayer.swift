//
//  XHPlayer.swift
//  XHPlayerDemo
//
//  Created by 李鑫浩 on 2017/10/18.
//  Copyright © 2017年 allens. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
import SnapKit
import Reachability

class XHView: UIView {
    
    //继承改变UIView的layer属性
    override class var layerClass: AnyClass {
            return AVPlayerLayer.self
    }
    
}

class XHPlayer: UIView {

    //是否重复播放
    open var isRepeat : Bool?
    //back
    var backBlock : (() -> Void)?
    //播放完毕的回调
    var playEndBlock : (() -> Void)?
    //播放失败的回调
    var playFailedBlock : (() -> Void)?
    
    //播放视图
    fileprivate var playView : XHView!
    //播放器遮罩
    fileprivate var playerMask : XHPlayerMaskView!
    //播放项
    fileprivate var  playerItem : AVPlayerItem!
    //播放器
    fileprivate var player : AVPlayer!
    //播放图层
    fileprivate var playerLayer : AVPlayerLayer!
    //播放图层
    fileprivate var volumeViewSlider : UISlider!
    //网络监测
    fileprivate var reachability: Reachability!
    //资源url
    fileprivate var assetUrl : NSString!
    //是否播放到结尾
    fileprivate var isPlayEnd : Bool!
    //播放监听
    fileprivate var timer : Timer!
    //加载倒计时
    fileprivate var loadingTimer : Timer!
    //是否是用户点击的暂停
    fileprivate var isUserPause : Bool!
    //原始界面亮度
    fileprivate var oriBrightness : CGFloat!
    //原始界面亮度
    fileprivate var lastBrightness : CGFloat!
    //总时长
    fileprivate var totalDuration : CGFloat!
    //总时长
    fileprivate var volume : CGFloat!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserPause = false
        self.createSubviews()
        self.createPlayer()
        self.initVolumeSliderView()
        self.initReachability()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.orientationChange(_:)), name: NSNotification.Name.UIDeviceOrientationDidChange, object: UIDevice.current)
        NotificationCenter.default.addObserver(self, selector: #selector(self.playEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.playerItem)
        NotificationCenter.default.addObserver(self, selector: #selector(self.appDidEnterBackground), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.appWillEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.appDidEnterForeground), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        if self.playerItem != nil {
            self.playerItem.removeObserver(self, forKeyPath: "status")
            self.playerItem.removeObserver(self, forKeyPath: "loadedTimeRanges")
            self.playerItem.removeObserver(self, forKeyPath: "playbackBufferEmpty")
            self.playerItem.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:-   初始化
    fileprivate func createSubviews() {
        self.playView = XHView()
        self.playView.backgroundColor = UIColor.clear
        self.insertSubview(self.playView, at: 0)
        
        self.playerMask = XHPlayerMaskView()
        weak var weakSelf = self
        self.playerMask.backBlock = {(isLandscape) -> Void in
            if isLandscape == true {
                weakSelf?.zoomOutBlockAction(!isLandscape)
            } else {
                if weakSelf?.backBlock != nil {
                    weakSelf?.backBlock!()
                }
            }
        }
        self.playerMask.zoomOutBlock = { (isToLandscape) -> Void in
           weakSelf?.zoomOutBlockAction(isToLandscape)
        }
        self.playerMask.playPauseBlock = { (isPause) -> Void in
            weakSelf?.playPauseBlockAction(isPause)
        }
        self.playerMask.sliderDragBeginBlock = { () -> Void in
            weakSelf?.sliderBeginBlockAction()
        }
        self.playerMask.sliderDragEndBlock = { (value) -> Void in
            weakSelf?.sliderDragEndBlockAction(value)
        }
        self.playerMask.panBlock = { (state, panOrientation, distance) -> Void in
            weakSelf?.panBlockAction(state, panOrientation, distance)
        }
        self.playerMask.tryPlayAgainBlock = {() -> Void in
            weakSelf?.tryPlayAgainBlockAction()
        }
        self.playerMask.continuePlayUse4GBlock = {(continuePlay) -> Void in
            weakSelf?.continuePlayUse4GBlockAction(continuePlay)
        }
        self.playView.addSubview(self.playerMask)
        
        self.playView.snp.makeConstraints { (make) in
            make.top.left.bottom.right.equalTo(0)
        }
        
        self.playerMask.snp.makeConstraints { (make) in
            make.top.left.bottom.right.equalTo(0)
        }
    }
    
    fileprivate func createPlayer() {
        self.player = AVPlayer()
        //强转self的layer的类型为AVPlayerLayer，然后作为AVPlayer的显示图层
        self.playerLayer = self.playView.layer as? AVPlayerLayer
        self.playerLayer!.player = self.player
        /**
         *resizeAspectFill      保持纵横比；充满屏幕，部分视图可能会被拉伸到屏幕外
         *resizeAspect          保持纵横比；适应屏幕，保持最大程度的全屏可见
         *resize                     拉伸填充层边界
         */
        self.playerLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        self.playerLayer.backgroundColor = UIColor.black.cgColor
    }
    
    fileprivate func initVolumeSliderView() -> Void {
        if self.volumeViewSlider == nil {
            let volumeView = MPVolumeView()
            for view in volumeView.subviews {
                if view is UISlider {
                    self.volumeViewSlider = view as! UISlider
                    break
                }
            }
        }
    }
    
    fileprivate func initReachability() -> Void {
        self.reachability = Reachability.init()
        weak var weakSelf = self
        // 网络可用或切换网络类型时执行
        self.reachability.whenReachable = { reachability in
            // 判断网络状态及类型
            if reachability.connection == .wifi {
                if weakSelf?.isUserPause == false && weakSelf?.playerMask.isPlayFail == false {
                    weakSelf?.play()
                    weakSelf?.playerMask.showNetworkStatus(reachability.connection)
                }
            } else if reachability.connection == .cellular {
                weakSelf?.playerMask.showNetworkStatus(reachability.connection)
                self.pause()
            } else {
                print("网络类型：无网络连接")
            }
        }
        
        // 网络不可用时执行
        self.reachability.whenUnreachable = { reachability in
            // 判断网络状态及类型
            if reachability.connection == .none {
                if weakSelf?.playerMask.isPlayFail == false {
                    weakSelf?.playerMask.showNetworkStatus(reachability.connection)
                }
            } 
        }
        do {
            // 开始监听
            try self.reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }
    
    //MARK:- Public method
    //设置播放资源链接
    public func setAssetUrl(_ url:NSString) -> Void {
        if !url .isKind(of: NSString.self) {
            print("请设置视频链接")
            return
        }
        if self.assetUrl != nil && (self.assetUrl?.isEqual(to: url as String))! {
            return
        }
        self.assetUrl = url
        if self.playerItem != nil {
            self.playerItem.removeObserver(self, forKeyPath: "status")
            self.playerItem.removeObserver(self, forKeyPath: "loadedTimeRanges")
            self.playerItem.removeObserver(self, forKeyPath: "playbackBufferEmpty")
            self.playerItem.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
            self.playerItem = nil
        }
        self.isPlayEnd = false
        self.playerMask.resetSubview()
        self.destoryTimer()
        if self.totalDuration != nil {
            self.totalDuration = nil
        }
        
        let asset = AVAsset(url: URL(string: url as String)!)
        self.playerItem = AVPlayerItem(asset: asset)
        self.player.replaceCurrentItem(with: self.playerItem)
        
        self.playerItem.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        self.playerItem.addObserver(self, forKeyPath: "loadedTimeRanges", options: .new, context: nil)
        self.playerItem.addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: nil)
        self.playerItem.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
    }
    
    //设置播放器标题
    public func setPlayerTitle(_ title : String) -> Void {
        self.playerMask.playerTitle.text = title
    }
    
    //播放
    public func play() -> Void {
        if self.isPlayEnd == true {
            self.playerMask.resetSubview()
            self.resetPlayerItem()
        }
        if self.player.timeControlStatus != .playing {
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(AVAudioSessionCategoryPlayback)
                try session.setActive(true)
                self.player.play()
            } catch {}
        }
        self.playerMask.playBtn.isSelected = false
        self.perform(#selector(self.startTimer), with: nil, afterDelay: 1.0)
    }
    
    //暂停播放
    public func pause() -> Void {
        self.playerMask.playBtn.isSelected = true
        self.player.pause()
        self.destoryTimer()
    }
    
    //销毁播放器
    public func destroyPlayer() -> Void {
        self.pause()
        self.destoryTimer()
        self.reachability.stopNotifier()
        self.player = nil
        self.playerItem = nil
        self.reachability = nil
    }
    
    //MARK:- Observe handle method
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (keyPath! as NSString).isEqual(to: "status") {
            if self.playerItem.status == .failed {
                self.playFailedAction()
            } else if self.playerItem.status == .readyToPlay {
                self.playerMask.showFailView(false)
            }
        } else if (keyPath! as NSString).isEqual(to: "loadedTimeRanges") {
            // 计算缓冲进度
            let timeInterval = self.availableDuration()
            let duration = self.playerItem.duration
            let totalDuration = CMTimeGetSeconds(duration)
            self.playerMask.loadProgress.setProgress(Float(timeInterval / totalDuration), animated: false)
        } else if (keyPath! as NSString).isEqual(to: "playbackBufferEmpty") {
            // 当缓冲是空的时候
            if self.playerItem.isPlaybackBufferEmpty {
                self.bufferingSomeTime()
            }
        } else if (keyPath! as NSString).isEqual(to: "playbackLikelyToKeepUp") {
            
        }
    }
    
    //MARK:- Private method
    fileprivate func destoryTimer() -> Void {
        if self.timer != nil {
            self.timer?.invalidate()
            self.timer = nil
        }
    }
    
    @objc fileprivate func startTimer() -> Void {
        self.destoryTimer()
        if self.timer == nil {
            self.timer = Timer.scheduledTimer(timeInterval: 0.02, target: self, selector: #selector(self.timeStack), userInfo: nil, repeats: true)
        }
    }
    
    @objc fileprivate func timeStack() -> Void {
        if self.playerItem.duration.timescale != 0 {
            if self.totalDuration == nil {
                self.totalDuration = CGFloat(CMTimeGetSeconds(self.playerItem.duration))
            }
            self.playerMask.setCurrentProgress(CGFloat(CMTimeGetSeconds(self.player.currentTime())), self.totalDuration)
        }
    }
    
    //播放出错
    fileprivate func playFailedAction() -> Void {
        self.pause()
        self.isUserPause = true
        self.playerMask.showLoadingView(false)
        self.playerMask.showFailView (true)
        if self.playFailedBlock != nil {
            self.playFailedBlock! ()
        }
    }
    
    fileprivate func resetPlayerItem() -> Void {
        self.isPlayEnd = false
        self.playerItem.seek(to: CMTimeMake(0, 1))
    }
    
    fileprivate func availableDuration() -> TimeInterval {
        let loadedTimeRanges = self.player.currentItem?.loadedTimeRanges
        //获得缓冲区域
        let timeRange = loadedTimeRanges?.first?.timeRangeValue
        let startSeconds = CMTimeGetSeconds((timeRange?.start)!)
        let durationSeconds = CMTimeGetSeconds((timeRange?.duration)!)
        //缓存总进度
        let result = startSeconds + durationSeconds
        return result
    }
    
    //网络慢的时候先暂停，预加载一会再播放
   fileprivate func bufferingSomeTime() -> Void {
        self.pause()
        self.playerMask.showLoadingView(true)
        if self.loadingTimer != nil {
            self.loadingTimer.invalidate()
            self.loadingTimer = nil
        }
        weak var weakSelf = self
        self.loadingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false, block: { (timer) in
            if weakSelf?.playerMask.isPlayFail == false {
                if (weakSelf?.playerItem.isPlaybackLikelyToKeepUp)! {
                    weakSelf?.play()
                    weakSelf?.playerMask.showLoadingView(false)
                } else {
                    if weakSelf?.reachability.connection == Reachability.Connection.none {
                        weakSelf?.playerMask.showNetworkStatus((weakSelf?.reachability.connection)!)
                        weakSelf?.playerMask.showLoadingView(false)
                    } else {
                        weakSelf?.bufferingSomeTime()
                    }
                }
            }
        })
    }
    
    fileprivate func landscapeOrientation() -> Void {
        self.playerMask.setupSubviews(true)
        self.window?.addSubview(self.playView)
        let screenBounds = UIScreen.main.bounds.size
        let width = max(screenBounds.width, screenBounds.height)
        let height = min(screenBounds.width, screenBounds.height)
        
        self.playView.snp.remakeConstraints({ (make) in
            make.centerX.equalTo(self.window!)
            make.centerY.equalTo(self.window!)
            make.size.equalTo(CGSize(width: width, height: height))
        })
    }
    
    fileprivate func originalOrientation() -> Void {
        self.playerMask.setupSubviews(false)
        self.insertSubview(self.playView, at: 0)
        self.playView.snp.remakeConstraints({ (make) in
            make.top.left.bottom.right.equalTo(0)
        })
    }
    
    //MARK:- Notification method
    @objc fileprivate func playEnd() -> Void {
        self.isPlayEnd = true
        if self.isRepeat == true {
            self.play()
        } else {
            self.isUserPause = true
            self.pause()
        }
        if self.playEndBlock != nil {
            self.playEndBlock!()
        }
    }
    
    @objc fileprivate func orientationChange(_ notify:NSNotification) {
        let orientation = UIDevice.current.orientation
        if (orientation == UIDeviceOrientation.landscapeLeft && XHPlayerCommon.supportOrientation(.landscapeRight)) || (orientation == UIDeviceOrientation.landscapeRight && XHPlayerCommon.supportOrientation(.landscapeLeft)) {
            self.landscapeOrientation()
        } else if orientation == UIDeviceOrientation.portrait && XHPlayerCommon.supportOrientation(.portrait) && (XHPlayerCommon.supportOrientation(.landscapeRight) || XHPlayerCommon.supportOrientation(.landscapeLeft)) {
            self.originalOrientation()
        }
    }
    
    @objc fileprivate func appDidEnterBackground() -> Void {
        UIScreen.main.brightness = 0.5
        self.pause()
    }
    
    @objc fileprivate func appWillEnterForeground() -> Void {
        if self.lastBrightness != nil {
            UIScreen.main.brightness = self.lastBrightness
        }
        if self.playerMask.isLandscape == true && XHPlayerCommon.supportOrientation(UIDeviceOrientation.landscapeLeft) == false{
            UIApplication.shared.setStatusBarOrientation(UIInterfaceOrientation.landscapeRight, animated: false)
        }
    }
    
    @objc fileprivate func appDidEnterForeground() -> Void {
        if self.isUserPause == false {
            self.play()
            self.playerMask.showHideMaskViewAction()
        }
    }
    
    //MARK:- Block method
    // 暂停、播放回调事件
    fileprivate func playPauseBlockAction(_ isPause : Bool) -> Void {
        self.isUserPause = isPause
        if isPause {
            self.pause()
        } else {
            if self.playerMask.isPlayFail || self.reachability.connection == .none {
                self.playerMask.showNetworkStatus(self.reachability.connection)
                self.playerMask.playBtn.isSelected = true
                return
            }
            self.play()
        }
    }
    
    //进度条拖拽开始回调
    fileprivate func sliderBeginBlockAction() -> Void {
        self.destoryTimer()
    }
    
    // 进度条拖拽停止回调
    fileprivate func sliderDragEndBlockAction(_ value : CGFloat) -> Void {
        self.isUserPause = false
        if self.playerMask.isPlayFail || self.totalDuration == nil{
            return
        }
        let dragedSeconds = self.totalDuration * CGFloat(value)
        let dragedTime = CMTimeMake(Int64(dragedSeconds), 1)
        self.player.seek(to: dragedTime)
        if self.playerItem.isPlaybackLikelyToKeepUp {
            self.play()
        } else {
            self.bufferingSomeTime()
        }
    }
    
    // 重新播放
    fileprivate func tryPlayAgainBlockAction() -> Void {
        let url = self.assetUrl
        self.assetUrl = nil
        self.setAssetUrl(url!)
        self.play()
        self.bufferingSomeTime()
        self.playerMask.showFailView (false)
    }
    
    //是否使用4G网络继续播放
    fileprivate func continuePlayUse4GBlockAction(_ continuePlay : Bool) -> Void {
        if continuePlay == false {
            if self.backBlock != nil {
                self.backBlock!()
            }
        } else {
            self.playPauseBlockAction(false)
        }
    }
    
    //屏幕旋转
    fileprivate func zoomOutBlockAction(_ isToLandscape : Bool) -> Void {
        if XHPlayerCommon.supportOrientation(.landscapeLeft) || XHPlayerCommon.supportOrientation(.landscapeRight) {
            if isToLandscape {
                if XHPlayerCommon.supportOrientation(.landscapeRight) {
                    UIDevice.current.setValue(NSNumber(value: Int8(UIDeviceOrientation.landscapeLeft.rawValue)), forKey: "orientation")
                } else {
                    UIDevice.current.setValue(NSNumber(value: Int8(UIDeviceOrientation.landscapeRight.rawValue)), forKey: "orientation")
                }
            } else {
                UIDevice.current.setValue(NSNumber(value: Int8(UIDeviceOrientation.portrait.rawValue)), forKey: "orientation")
            }
        } else {
            if isToLandscape {
                UIApplication.shared.setStatusBarOrientation(UIInterfaceOrientation.landscapeRight, animated: false)
                self.landscapeOrientation()
                UIView.animate(withDuration: 0.25, animations: {
                    self.playView.transform = CGAffineTransform.init(rotationAngle: CGFloat(Double.pi / 2))
                })
            } else {
                UIApplication.shared.setStatusBarOrientation(UIInterfaceOrientation.portrait, animated: false)
                self.originalOrientation()
                UIView.animate(withDuration: 0.25, animations: {
                    self.playView.transform = CGAffineTransform.identity
                })
            }
        }
    }
    
    fileprivate func panBlockAction(_ state : UIGestureRecognizerState , _ panOrientation : XHPanOrientationType, _ distance : CGFloat) -> Void {
        if state == .began {
            if panOrientation == XHPanOrientationType.XHPanOrientationTypeLeft {
                self.oriBrightness = UIScreen.main.brightness
            } else if panOrientation == XHPanOrientationType.XHPanOrientationTypeRight {
                self.volume = CGFloat(self.volumeViewSlider.value)
            }
        } else {
            if panOrientation == XHPanOrientationType.XHPanOrientationTypeLeft {
                self.lastBrightness = -distance / (self.frame.size.height) + self.oriBrightness
                UIScreen.main.brightness = self.lastBrightness
            } else if panOrientation == XHPanOrientationType.XHPanOrientationTypeRight {
                self.volumeViewSlider.value = Float(-distance / (self.frame.size.height) + self.volume)
            } else {
                if self.playerMask.isPlayFail {
                    return
                }
                let timerinterval : NSInteger = NSInteger(distance / (self.frame.size.width / 60))
                if state == .ended {
                    self.playerMask.setForwardView(timerinterval, false)
                    let dragedSeconds = CGFloat(CMTimeGetSeconds(self.player.currentTime())) + CGFloat(timerinterval)
                    let dragedTime = CMTimeMake(Int64(dragedSeconds), 1)
                    self.player.seek(to: dragedTime)
                    if self.playerItem.isPlaybackBufferEmpty {
                        self.bufferingSomeTime()
                    } else {
                        self.play()
                    }
                } else {
                    self.playerMask.setForwardView(timerinterval, true)
                }
            }
        }
    }
}
