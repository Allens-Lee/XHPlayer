//
//  WBRoundViewHUD.swift
//  WBLoadingView
//
//  Created by zwb on 2017/6/26.
//  Copyright © 2017年 HengSu Co., LTD. All rights reserved.
//

import UIKit

/// 加载中的动画，默认为视图中心，大小为(50, 50)
open class WBRoundViewHUD: UIView {
    
    /// 运动的效果状态
    ///
    /// - uniform: 匀速运动
    /// - gradient: 渐变运动
    public enum HUDType {
        case  uniform, gradient
    }

    /// 线条颜色，默认为 UIColor.white
    public var roundColor: UIColor?
    {
        didSet {
            if roundColor ==  oldValue { return }
            guard let newColor = roundColor else { return }
            setCaLayerColor(newColor)
        }
    }
    
    /// 动画运动的时长，默认为1s
    public var duration: CFTimeInterval = 1.0
    
    private var _type: HUDType = .uniform  // 动画的类型，默认为 .uniform
    open var _animationCount = 0  // 已运动的小球个数
    
    open private(set) var _caLayers: [CALayer]?
    
    open static let defaultWidth:CGFloat = 50
    private let loadingWidth = WBRoundViewHUD.defaultWidth // 默认大小
    private let max_count:Int = 6    // 一共有多少个小球
    private let s_w = UIScreen.main.bounds.size.width
    private let s_h = UIScreen.main.bounds.size.height
    
    // MARK:  -  Clicye Life
    
    ///  初始化HUD
    ///
    /// - Parameters:
    ///   - frame: 视图frame，默认中心为屏幕中心，大小为 (50, 50)
    ///   - type: 动画运动的类型，默认为 .uniform
    ///   - roundColor: 线条颜色，默认为 [UIColor whiteColor]
    public convenience init(frame: CGRect, type: HUDType = .uniform, roundColor: UIColor? = nil) {
        self.init(frame: frame)
        
        self.roundColor = roundColor
        if roundColor == nil {
            self.roundColor = .white
        }
        _type = type
        
        initializeInterface()
    }
    
    private func initializeInterface() {
        
        if self.frame == .zero {
            self.frame = CGRect(x: (s_w - loadingWidth) / 2, y: (s_h - loadingWidth) / 2, width: loadingWidth, height: loadingWidth)
        }
        layer.cornerRadius = 5.0
        backgroundColor = UIColor(white: 0.0, alpha: 0.95)
//        backgroundColor = UIColor.clear
        
        if _caLayers == nil {
            _caLayers = [CALayer]()
        }
        
        let width = bounds.size.width
        let layerCenter = CGPoint(x: width / 6 * 5, y: bounds.size.height / 2)

        for _ in 0..<max_count {
            let _layer = CALayer()
            _layer.position = layerCenter
            _layer.bounds = CGRect(x: 0, y: 0, width: width / 10, height: width / 10)
            _layer.backgroundColor = roundColor?.cgColor
            _layer.cornerRadius = width / 20
            _layer.isHidden = true
            layer.addSublayer(_layer)
            
            _caLayers?.append(_layer)
        }
    }
    
    /// 重置线条颜色
    ///
    /// - Parameter color: 颜色
    private func setCaLayerColor(_ color: UIColor) {
        _caLayers?.forEach {
            $0.backgroundColor = color.cgColor
        }
    }
    
    // MARK: - Start Animations
    open func start() {
        
        // 有动画，直接返回
        if let _ = _caLayers?.first?.animationKeys() { return }
        
        let width = bounds.size.width
        let theCenter = CGPoint(x: width / 2, y: bounds.size.height / 2)
        var path = UIBezierPath(arcCenter: theCenter, radius: width / 3, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        
        // 帧动画
        let animation = CAKeyframeAnimation()
        animation.keyPath = "position"
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false
        // 小球动画匀速运动
        if _type == .uniform {
            animation.path = path.cgPath
            animation.duration = duration
            animation.calculationMode = kCAAnimationCubicPaced
            animation.repeatCount = .infinity
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
            
            // 为每一个Layer添加动画
            guard let count = _caLayers?.count else { return }
            for index in 0..<count {
                // 使第一个小球将要运动到最初的位置的时候，最后一个小球刚开始动画
                animation.beginTime = duration / CFTimeInterval(count) * CFTimeInterval(index + 1)
                _caLayers?[index].isHidden = false
                _caLayers?[index].add(animation, forKey: "Layer_animation")
            }
        }else{
             // 小球运行做渐变动画<前半圈动画>
            path = UIBezierPath(arcCenter: theCenter, radius: width / 3, startAngle: 0, endAngle: .pi, clockwise: true)
            animation.path = path.cgPath
            animation.duration = duration / 2
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            
            path = UIBezierPath(arcCenter: theCenter, radius: width / 3, startAngle: -.pi, endAngle: 0, clockwise: true)
            // 帧动画
            let upAnimation = CAKeyframeAnimation()
            upAnimation.keyPath = "position"
            upAnimation.fillMode = kCAFillModeForwards
            upAnimation.isRemovedOnCompletion = false
            // 小球运行做渐变动画<后半圈动画>
            upAnimation.path = path.cgPath
            upAnimation.duration = duration / 2
            upAnimation.beginTime = duration / 2
            upAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            
            let group = CAAnimationGroup()
            group.duration = duration
            group.delegate = self
            group.animations = [animation, upAnimation]
            
            guard let count = _caLayers?.count else { return }
            // 为每一个Layer添加动画
            for index in 0..<count {
                // 使第一个小球将要运动到对面(即半个圈)位置的时候，最后一个小球刚开始动画
                let time = duration / 2 / CFTimeInterval(count) * CFTimeInterval(index + 1)
                DispatchQueue.main.asyncAfter(deadline: .now() + time, execute: { 
                    self._caLayers?[index].isHidden = false
                    self._caLayers?[index].add(group, forKey: "index_Layer_animation")
                })
            }
        }
    }
    
    // MARK: - Stop Animations
    open func stop() {
        _caLayers?.forEach {
            $0.removeAllAnimations()
        }
    }
    
    // MARK: - Hidden
    open func hide(_ animated: Bool = true) {
        if animated {
            UIView.animate(withDuration: 0.1, animations: {
                self.stop()
                self.alpha = 0
            }, completion: { (_) in
                self.removeFromSuperview()
            })
        }else {
            self.stop()
            self.removeFromSuperview()
        }
    }
}

// MARK: - CAAnimationDelegate
extension WBRoundViewHUD : CAAnimationDelegate {
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if !flag { return }
        // 小球动画运动完成之后，对其隐藏并移除动画
        let _layer = _caLayers?[_animationCount]
        _layer?.isHidden = true
        _layer?.removeAllAnimations()
        _animationCount += 1
        // 到最后一个小球运动完成，开始下一轮的动画
        if let count = _caLayers?.count, _animationCount == count {
            _animationCount = 0
            // 稍微延迟0.1s，使其最后一个隐藏
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { 
                self.start()
            })
        }
    }
}

// MARK: - Show To View
extension WBRoundViewHUD {
    /// 添加到指定的View视图上
    ///
    /// - Parameters:
    ///   - toView: 需要添加的view
    ///   - isAnimated: 是否开启动画
    @discardableResult
    open class func show(_ toView: UIView, type hudType: WBRoundViewHUD.HUDType = .uniform, animated isAnimated: Bool = true) -> WBRoundViewHUD {
        let rect = CGRect(x: (toView.bounds.size.width - WBRoundViewHUD.defaultWidth) / 2, y: (toView.bounds.size.height - WBRoundViewHUD.defaultWidth) / 2, width: WBRoundViewHUD.defaultWidth, height: WBRoundViewHUD.defaultWidth)
        let hud = WBRoundViewHUD(frame: rect, type: hudType, roundColor: nil)
        hud.backgroundColor = UIColor(white: 0.0, alpha: 0.05)
        for subView in toView.subviews {
            if subView is WBRoundViewHUD {
                if !isAnimated {
                    (subView as! WBRoundViewHUD).stop()
                }else{
                    (subView as! WBRoundViewHUD).start()
                }
                return subView as! WBRoundViewHUD
            }
        }
        toView.addSubview(hud)
        toView.bringSubview(toFront: hud)
        if !isAnimated {
            hud.stop()
        }else{
            hud.start()
        }
        return hud
    }
}
