//
//  XHPlayerMaskView.swift
//  XHPlayerDemo
//
//  Created by 李鑫浩 on 2017/10/18.
//  Copyright © 2017年 allens. All rights reserved.
//

import UIKit
import SnapKit
import Reachability

enum XHPanOrientationType {
    case XHPanOrientationTypeLeft                           //左边屏幕上下滑动
    case XHPanOrientationTypeLandscape               //屏幕横滑动
    case XHPanOrientationTypeRight                        //右边屏幕上下滑动
}

class XHPlayerMaskView: UIView {

    //是否是横屏状态
    public var isLandscape : Bool!
    //是否是播放失败
    public var isPlayFail : Bool!
    
    //状态栏
    fileprivate var statusBar : UIView!
    //底部工具栏
    fileprivate var bottomToolBar : UIView!
    //顶部部工具栏
    fileprivate var topToolBar : UIView!
    //播放失败页面
    fileprivate var failView : UIView!
    //前进或是后退页面
    fileprivate var forwardView : UILabel!
    //加载指示器
    fileprivate var loadingHUD : WBRoundViewHUD!
    //网络状态标签
    fileprivate var networkStatusFlag : UILabel!
    //网络状态切换提示页面
    fileprivate var reminderView : UIView!
    
    //返回按钮
    var backBtn : UIButton!
    //视频标题
    var playerTitle : UILabel!
    //播放/暂停功能
    var playBtn : UIButton!
    //全屏
    var fullBtn : UIButton!
    //进度条
    fileprivate var slider : XHSlider!
    //加载进度条
    var loadProgress : UIProgressView!
    //播放时间
    fileprivate var timeLable : UILabel!
    //是否正在拖拽
    fileprivate var isDraging : Bool!
    //是否显示MaskView
    fileprivate var isShowMaskView : Bool!
    //计时器
    fileprivate var timer : Timer!
    //屏幕滑动手势方向
    fileprivate var panOrientation : XHPanOrientationType!
    

    //back
    var backBlock : ((Bool) -> Void)?
    //播放/暂停
    var playPauseBlock : ((Bool) -> Void)?
    //屏幕放大/缩小
    var zoomOutBlock : ((Bool) -> Void )?
    //进度条拖拽中事件
    var sliderDragBeginBlock : (() -> Void)?
    //进度条拖拽停止事件
    var sliderDragEndBlock : ((CGFloat) -> Void)?
    //进度条拖拽停止事件
    var panBlock : ((UIGestureRecognizerState,XHPanOrientationType, CGFloat) -> Void)?
    //重试播放
    var tryPlayAgainBlock : (() -> Void)?
    //是否使用4G继续播放
    var continuePlayUse4GBlock : ((Bool) -> Void)?
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isDraging = false
        self.isShowMaskView = true
        self.isLandscape = false
        self.statusBar = (UIApplication.shared.value(forKey: "statusBarWindow") as! UIView).value(forKey: "statusBar") as! UIView
        self.createTopToolBar()
        self.createbottomToolBar()
        self.addGesture()
        self.timerStack()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:- 页面初始化
    fileprivate func createTopToolBar() -> Void {
        self.topToolBar = UIView()
        self.topToolBar.isUserInteractionEnabled = true
        self.addSubview(self.topToolBar)
        
        self.backBtn = UIButton()
        self.backBtn.setImage(XHPlayerCommon.imageWithName("player_back"), for: .normal)
        self.backBtn.setImage(XHPlayerCommon.imageWithName("landscape_back"), for: .selected)
        self.backBtn.imageView?.contentMode = UIViewContentMode.scaleAspectFit
        self.backBtn.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        self.backBtn.addTarget(self, action: #selector(self.backAction), for: .touchUpInside)
        self.topToolBar.addSubview(self.backBtn)
        
        self.playerTitle = UILabel()
        self.playerTitle.textColor = UIColor.white
        self.playerTitle.font = UIFont.systemFont(ofSize: 16)
        self.playerTitle.isHidden = true
        self.topToolBar.addSubview(self.playerTitle)
        
        self.topToolBar.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.left.right.equalTo(0)
            make.height.equalTo(40)
        }
        
        self.backBtn.snp.makeConstraints { (make) in
            make.top.left.bottom.equalTo(00)
            make.width.equalTo(40)
            }
        
        self.playerTitle.snp.makeConstraints { (make) in
            make.left.equalTo(self.backBtn.snp.right)
            make.right.equalTo(-20)
            make.centerY.equalTo(self.backBtn)
        }
    }
    
    fileprivate func createbottomToolBar() -> Void {
        self.bottomToolBar = UIView()
        self.bottomToolBar.isUserInteractionEnabled = true
        self.addSubview(self.bottomToolBar)
        
        self.playBtn = UIButton()
        self.playBtn.setImage(XHPlayerCommon.imageWithName("player_pause"), for: .normal)
        self.playBtn.setImage(XHPlayerCommon.imageWithName("player_play"), for: .selected)
        self.playBtn.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        self.playBtn.addTarget(self, action: #selector(self.playPauseAction), for: .touchUpInside)
        self.bottomToolBar.addSubview(self.playBtn)
        
        self.loadProgress = UIProgressView()
        self.loadProgress.trackTintColor = UIColor.clear
        self.loadProgress.progressTintColor = UIColor.init(white: 1, alpha: 0.6)
        self.loadProgress.layer.cornerRadius = 1.5
        self.loadProgress.layer.masksToBounds = true
        self.bottomToolBar.addSubview(self.loadProgress)
        
        self.slider = XHSlider()
        self.slider.minimumTrackTintColor = UIColor.init(white: 1, alpha: 0.8)
        self.slider.maximumTrackTintColor = UIColor.init(white: 1, alpha: 0.3)
        self.slider.addTarget(self, action: #selector(self.sliderDragBegin), for: .valueChanged)
        self.slider.addTarget(self, action: #selector(self.sliderDragEnd), for: .touchUpInside)
        self.slider.addTarget(self, action: #selector(self.sliderDragEnd), for: .touchUpOutside)
        self.slider.addTarget(self, action: #selector(self.sliderDragEnd), for: .touchCancel)
        self.bottomToolBar.addSubview(self.slider)
        
        self.timeLable = UILabel()
        self.timeLable.textColor = UIColor.white
        self.timeLable.font = UIFont.systemFont(ofSize: 12)
        self.timeLable.textAlignment = .right
        self.bottomToolBar.addSubview(self.timeLable)
        
        self.fullBtn = UIButton()
        self.fullBtn.setImage(XHPlayerCommon.imageWithName("player_out"), for: .normal)
        self.fullBtn.setImage(XHPlayerCommon.imageWithName("player_zoom"), for: .selected)
        self.fullBtn.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        self.fullBtn.addTarget(self, action: #selector(self.zoomOutAction), for: .touchUpInside)
        self.bottomToolBar.addSubview(self.fullBtn)
        
        self.bottomToolBar.snp.makeConstraints { (make) in
            make.left.bottom.right.equalTo(0)
            make.height.equalTo(40)
        }
        
        self.playBtn.snp.makeConstraints { (make) in
            make.left.equalTo(00)
            make.bottom.equalTo(00)
            make.size.equalTo(CGSize(width: 40, height: 40))
        }
        
        self.loadProgress.snp.makeConstraints { (make) in
            make.left.equalTo(self.slider).offset(5)
            make.right.equalTo(self.slider).offset(-5)
            make.centerY.equalTo(self.slider)
            make.height.equalTo(3)
        }
        
        self.slider.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.playBtn)
            make.left.equalTo(self.playBtn.snp.right)
            make.right.equalTo(self.timeLable.snp.left)
        }
        self.timeLable.snp.makeConstraints { (make) in
            make.right.equalTo(self.fullBtn.snp.left)
            make.top.bottom.equalTo(0)
            make.width.equalTo(85)
        }
        
        self.fullBtn.snp.makeConstraints { (make) in
            make.right.equalTo(0)
            make.centerY.equalTo(self.playBtn)
            make.size.equalTo(CGSize(width: 40, height: 40))
        }
    }
    
    func createFailView() -> Void {
        if self.failView == nil {
            self.failView = UIView()
            self.failView.backgroundColor = UIColor.clear
            self.failView.isHidden = true
            self.insertSubview(self.failView, at: 0)
            
            let failTitle = UILabel()
            failTitle.textColor = UIColor.white
            failTitle.font = UIFont.systemFont(ofSize: 15)
            failTitle.text = "播放出错啦，请检查网络后重试~~~"
            self.failView.addSubview(failTitle)
            
            let tryAgain = UIButton()
            tryAgain.backgroundColor = UIColor.cyan
            tryAgain.setTitleColor(UIColor.white, for: .normal)
            tryAgain.titleLabel?.font = UIFont.systemFont(ofSize: 13)
            tryAgain.setTitle("重试", for: .normal)
            tryAgain.layer.cornerRadius = 3
            tryAgain.layer.masksToBounds = true
            tryAgain.addTarget(self, action: #selector(self.tryPlayAgain), for: .touchUpInside)
            self.failView.addSubview(tryAgain)
            
            self.failView.snp.makeConstraints { (make) in
                make.top.equalTo(self.topToolBar.snp.bottom)
                make.bottom.equalTo(self.bottomToolBar.snp.top)
                make.left.right.equalTo(0)
            }
            
            failTitle.snp.makeConstraints { (make) in
                make.centerX.equalTo(self.failView)
                make.centerY.equalTo(self.failView).offset(-20)
            }
            
            tryAgain.snp.makeConstraints { (make) in
                make.centerX.equalTo(self.failView)
                make.centerY.equalTo(self.failView).offset(20)
                make.size.equalTo(CGSize(width: 60, height: 30))
            }
        }
    }
    
    fileprivate func createLoadingView() -> Void {
        if self.loadingHUD == nil {
            self.loadingHUD = WBRoundViewHUD(frame: CGRect.zero, type: .gradient, roundColor: nil)
            self.loadingHUD.duration = 2.0
            self.loadingHUD.roundColor = .orange
            self.loadingHUD.backgroundColor = UIColor.clear
            self.loadingHUD.isHidden = true
            self.addSubview(self.loadingHUD)
            
            self.loadingHUD.snp.makeConstraints { (make) in
                make.centerX.equalTo(self)
                make.centerY.equalTo(self)
                make.size.equalTo(CGSize(width: 50, height: 50))
            }
        }
    }
    
    //前进或是后退的标签
    fileprivate func createForwardFlagView() -> Void {
        if self.forwardView == nil {
            self.forwardView = UILabel()
            self.forwardView.textColor = UIColor.white
            self.forwardView.font = UIFont.systemFont(ofSize: 12)
            self.forwardView.textAlignment = .center
            self.forwardView.backgroundColor = UIColor.init(white: 0, alpha: 0.8)
            self.forwardView.layer.cornerRadius = 3
            self.forwardView.layer.masksToBounds = true
            self.forwardView.isHidden = true
            self.addSubview(self.forwardView)
            
            self.forwardView.snp.makeConstraints({ (make) in
                make.centerX.equalTo(self)
                make.centerY.equalTo(self)
                make.size.equalTo(CGSize(width: 60, height: 25))
            })
        }
    }
    
    fileprivate func createNetworkStatusFlagView() -> Void {
        if self.networkStatusFlag == nil {
            self.networkStatusFlag = UILabel()
            self.networkStatusFlag.textColor = UIColor.white
            self.networkStatusFlag.textAlignment = .center
            self.networkStatusFlag.font = UIFont.systemFont(ofSize: 14)
            self.networkStatusFlag.alpha = 0.0
            self.networkStatusFlag.isHidden = true
            self.networkStatusFlag.backgroundColor = UIColor.init(white: 0, alpha: 0.8)
            self.networkStatusFlag.layer.cornerRadius = 3
            self.networkStatusFlag.layer.masksToBounds = true
            self.addSubview(self.networkStatusFlag)
            
            self.networkStatusFlag.snp.makeConstraints({ (make) in
                make.centerX.equalTo(self)
                make.bottom.equalTo(self)
                make.size.equalTo(CGSize(width: 60, height: 25))
            })
        }
    }
    
    fileprivate func createReminderView() -> Void {
        if self.reminderView == nil {
            self.reminderView = UIView()
            self.reminderView.backgroundColor = UIColor.init(white: 0, alpha: 0.8)
            self.reminderView.isHidden = true
            self.reminderView.layer.cornerRadius = 3
            self.reminderView.layer.masksToBounds = true
            self.addSubview(self.reminderView)
            
            let reminderTitle = UILabel()
            reminderTitle.textColor = UIColor.white
            reminderTitle.font = UIFont.systemFont(ofSize: 15)
            reminderTitle.attributedText = XHPlayerCommon.attributedStringWithSpaceHeight("WiFi中断，播放会使用流\n量，是否继续？", 5.0)
            reminderTitle.numberOfLines = 2
            reminderTitle.textAlignment = .center
            self.reminderView.addSubview(reminderTitle)
            
            let canclePlay = UIButton()
            canclePlay.backgroundColor = UIColor.clear
            canclePlay.setTitleColor(UIColor.white, for: .normal)
            canclePlay.titleLabel?.font = UIFont.systemFont(ofSize: 15)
            canclePlay.setTitle("取消播放", for: .normal)
            canclePlay.layer.cornerRadius = 3
            canclePlay.layer.borderColor = UIColor.init(white: 1, alpha: 0.5).cgColor
            canclePlay.layer.borderWidth = 0.8
            canclePlay.tag = 100
            canclePlay.addTarget(self, action: #selector(self.continuePlayUse4G(_:)), for: .touchUpInside)
            self.reminderView.addSubview(canclePlay)
            
            let continuePlay = UIButton()
            continuePlay.backgroundColor = UIColor.clear
            continuePlay.setTitleColor(UIColor.white, for: .normal)
            continuePlay.titleLabel?.font = UIFont.systemFont(ofSize: 15)
            continuePlay.setTitle("继续播放", for: .normal)
            continuePlay.layer.cornerRadius = 3
            continuePlay.layer.borderColor = UIColor.init(white: 1, alpha: 0.5).cgColor
            continuePlay.layer.borderWidth = 0.8
            continuePlay.tag = 101
            continuePlay.addTarget(self, action: #selector(self.continuePlayUse4G(_:)), for: .touchUpInside)
            self.reminderView.addSubview(continuePlay)
            
            self.reminderView.snp.makeConstraints { (make) in
                make.centerX.equalTo(self)
                make.centerY.equalTo(self)
                make.size.equalTo(CGSize(width: 200, height: 120))
            }
            
            reminderTitle.snp.makeConstraints { (make) in
                make.centerX.equalTo(self.reminderView)
                make.top.equalTo(20)
            }
            
            canclePlay.snp.makeConstraints { (make) in
                make.centerX.equalTo(self.reminderView).offset(-50)
                make.bottom.equalTo(-15)
                make.size.equalTo(CGSize(width: 80, height: 30))
            }
            
            continuePlay.snp.makeConstraints { (make) in
                make.centerX.equalTo(self.reminderView).offset(50)
                make.centerY.equalTo(canclePlay)
                make.size.equalTo(CGSize(width: 80, height: 30))
            }
        }
    }
    
    //MARK:- Private method
    fileprivate func destoryTimer() -> Void {
        if self.timer != nil {
            self.timer?.invalidate()
            self.timer = nil
        }
    }
    
    fileprivate func timerStack() -> Void {
        weak var weakSelf = self
        self.destoryTimer()
        self.timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false, block: { (timer) in
            if weakSelf?.isShowMaskView == true {
                weakSelf?.showHideMaskViewAction()
            }
        })
    }
    
    fileprivate func addGesture() -> Void {
        let gestureView : UIView = UIView()
        gestureView.backgroundColor = UIColor.clear
        self.insertSubview(gestureView, at: 0)
        gestureView.snp.makeConstraints { (make) in
            make.left.right.equalTo(0)
            make.top.equalTo(self.topToolBar.snp.bottom)
            make.bottom.equalTo(self.bottomToolBar.snp.top)
        }
        
        //单击 显示/隐藏MaskView
        let singleTap = UITapGestureRecognizer.init(target: self, action: #selector(self.singleTapGestureAction))
        self.addGestureRecognizer(singleTap)
        //双击 暂停/播放
        let doubleTap = UITapGestureRecognizer.init(target: self, action: #selector(self.doubleTapGestureAction))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.numberOfTouchesRequired = 1
        self.addGestureRecognizer(doubleTap)
        singleTap.require(toFail: doubleTap)
        //拖移 前进/后退
        let panGes = UIPanGestureRecognizer.init(target: self, action: #selector(self.panGestureAction(_:)))
        panGes.maximumNumberOfTouches = 1
        gestureView.addGestureRecognizer(panGes)
    }
    
    //MARK:- Public method
    //重置页面
    public func resetSubview() -> Void {
        self.playBtn.isSelected = true
        self.slider.value = 0
        self.loadProgress.setProgress(0, animated: false)
        self.timeLable.text = "00:00 ∕ 00:00"
    }
    
    public func setupSubviews(_ islandscape : Bool) -> Void {
        self.isLandscape = islandscape
        var top = 0
        if islandscape {
            top = 20
            self.statusBar.isHidden = false
            self.fullBtn.isSelected = true
            self.playerTitle.isHidden = false
            self.backBtn.setImage(XHPlayerCommon.imageWithName("landscape_back"), for: .normal)
        } else {
            top = 0
            self.fullBtn.isSelected = false
            self.playerTitle.isHidden = true
            self.backBtn.setImage(XHPlayerCommon.imageWithName("player_back"), for: .normal)
        }
        self.isShowMaskView = false
        self.showHideMaskViewAction()
        self.timerStack()
        
        self.topToolBar.snp.remakeConstraints { (make) in
            make.top.equalTo(top)
            make.left.right.equalTo(0)
            make.height.equalTo(40)
        }
    }
    
    func setForwardView(_ timeinterval : NSInteger, _ show : Bool) -> Void {
        self.createForwardFlagView()
        self.forwardView.isHidden = !show
        if timeinterval >= 0 {
            self.forwardView.text = "前进\(timeinterval)秒"
        } else {
            self.forwardView.text = "后退\(abs(timeinterval))秒"
        }
    }
    
    public func setCurrentProgress(_ currentDuration : CGFloat, _ totalDuration : CGFloat) -> Void {
        if self.isDraging == false {
            if totalDuration >= 3600.0 {
                if currentDuration >= 3600.0 {
                    self.timeLable.snp.updateConstraints({ (make) in
                        make.width.equalTo(120)
                    })
                } else {
                    self.timeLable.snp.updateConstraints({ (make) in
                        make.width.equalTo(100)
                    })
                }
            } else {
                self.timeLable.snp.updateConstraints({ (make) in
                    make.width.equalTo(85)
                })
            }
            self.timeLable.text = XHPlayerCommon.timeStringWithDuration(currentDuration) as String + (" ∕ " + (XHPlayerCommon.timeStringWithDuration(totalDuration) as String) as String)
            self.slider.value = Float(currentDuration / totalDuration)
        }
    }
    
    public func showFailView(_ show : Bool) -> Void {
        self.createFailView()
        self.isPlayFail = show
        self.failView.isHidden = !show
    }
    
    public func showLoadingView(_ show : Bool) -> Void {
        self.createLoadingView()
        if show {
            self.loadingHUD.isHidden = false
            self.loadingHUD.start()
        } else {
            self.loadingHUD.stop()
            self.loadingHUD.isHidden = true
        }
    }
    
    public func showNetworkStatus(_ status : Reachability.Connection) -> Void {
        if status == .none || status == .wifi {
            self.createNetworkStatusFlagView()
            self.reminderView.isHidden = true
            if self.networkStatusFlag.isHidden == true {
                if status == .none {
                    self.networkStatusFlag.snp.updateConstraints({ (make) in
                        make.width.equalTo(210)
                    })
                    self.networkStatusFlag.text = "当前网络不可用，请检查网络设置"
                } else {
                    self.networkStatusFlag.snp.updateConstraints({ (make) in
                        make.width.equalTo(165)
                    })
                    self.networkStatusFlag.text = "已自动使用WiFi网络播放"
                }
                self.networkStatusFlag.isHidden = false
                UIView.animate(withDuration: 0.5, animations: {
                    self.networkStatusFlag.alpha = 1.0
                    self.networkStatusFlag.transform = CGAffineTransform.init(translationX: 0, y: -15)
                }, completion: { (finish) in
                    if finish {
                        weak var weakSelf = self
                        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false, block: { (timer) in
                            UIView.animate(withDuration: 0.5, animations: {
                                weakSelf?.networkStatusFlag.alpha = 0.0
                            }, completion: { (finish) in
                                weakSelf?.networkStatusFlag.transform = CGAffineTransform.identity
                                weakSelf?.networkStatusFlag.isHidden = true
                            })
                        })
                    }
                })
            }
        } else {
            self.createReminderView()
            self.reminderView.isHidden = false
            self.bottomToolBar.isUserInteractionEnabled = false
        }
    }
    
    @objc public func showHideMaskViewAction() -> Void {
        if self.isShowMaskView == true {
            self.isShowMaskView = false
            UIView.animate(withDuration: 0.5, animations: {
                self.topToolBar.alpha = 0.0
                self.bottomToolBar.alpha = 0.0
                if self.isLandscape {
                    self.statusBar.alpha = 0.0
                }
            })
        } else {
            self.isShowMaskView = true
            UIView.animate(withDuration: 0.5, animations: {
                self.topToolBar.alpha = 1.0
                self.bottomToolBar.alpha = 1.0
                if self.isLandscape {
                    self.statusBar.alpha = 1.0
                }
            })
        }
    }
    
    //MARK:- Target method
    @objc fileprivate func backAction() -> Void {
        if self.backBlock != nil {
            self.backBlock!(self.isLandscape)
        }
    }
    
    @objc fileprivate func playPauseAction() -> Void {
        let pause : Bool = !self.playBtn.isSelected
        if self.playPauseBlock != nil {
            self.playPauseBlock! (pause)
        }
    }
    
    @objc fileprivate func zoomOutAction() -> Void {
        let out : Bool = !self.fullBtn.isSelected
        if self.zoomOutBlock != nil {
            self.zoomOutBlock! (out)
        }
    }
    
    //滑动拖动中
    @objc fileprivate func sliderDragBegin() -> Void {
        self.isDraging = true
        self.destoryTimer()
        if self.sliderDragBeginBlock != nil {
            self.sliderDragBeginBlock! ()
        }
    }
    
    //结束滑动
    @objc fileprivate func sliderDragEnd() -> Void {
        self.isDraging = false
        self.timerStack()
        if self.sliderDragEndBlock != nil {
            self.sliderDragEndBlock! (CGFloat(self.slider.value))
        }
    }
    
    @objc fileprivate func tryPlayAgain() -> Void {
        if self.tryPlayAgainBlock != nil {
            self.tryPlayAgainBlock! ()
        }
    }
    
    @objc fileprivate func continuePlayUse4G(_ sender : UIButton) -> Void {
        var continuePlay : Bool = false
        if sender.tag == 101 {
            continuePlay = true
            self.bottomToolBar.isUserInteractionEnabled = true
            self.reminderView.isHidden = true
        }
        if self.continuePlayUse4GBlock != nil {
            self.continuePlayUse4GBlock!(continuePlay)
        }
    }
    
    //MARK:- Gesture method
    //单击
    @objc fileprivate func singleTapGestureAction() -> Void {
        self.showHideMaskViewAction()
        self.timerStack()
    }
    
    //双击
    @objc fileprivate func doubleTapGestureAction() -> Void {
        if self.reminderView != nil && self.reminderView.isHidden == false {
            return
        }
        self.isShowMaskView = false
        self.showHideMaskViewAction()
        self.timerStack()
        self.playPauseAction()
    }
    
    //拖移
    @objc fileprivate func panGestureAction(_ gesture : UIPanGestureRecognizer) -> Void {
        if self.reminderView != nil && self.reminderView.isHidden == false {
            return
        }
        var distance : CGFloat?
        let translation = gesture.translation(in: self)
        if gesture.state == .began {
            distance = 0
            let locationPoint = gesture.location(in: self)
            if locationPoint.x < self.frame.size.width / 2.0 && abs(translation.y) > abs(translation.x)  && self.isLandscape{
                self.panOrientation = XHPanOrientationType.XHPanOrientationTypeLeft
            } else if locationPoint.x > self.frame.size.width / 2.0 && abs(translation.y) > abs(translation.x)  && self.isLandscape{
                self.panOrientation = XHPanOrientationType.XHPanOrientationTypeRight
            } else {
                self.panOrientation = XHPanOrientationType.XHPanOrientationTypeLandscape
            }
        } else {
            if self.panOrientation == XHPanOrientationType.XHPanOrientationTypeLeft {
                distance = translation.y
            } else if self.panOrientation == XHPanOrientationType.XHPanOrientationTypeRight {
                distance = translation.y
            } else {
                distance = translation.x
            }
        }
        if self.panBlock != nil {
            self.panBlock! (gesture.state,self.panOrientation, distance!)
        }
    }
}
