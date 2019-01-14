//
//  JoyStickView.swift
//  RoseGold iOS
//
//  Created by Tatsuhiro Aoshima on 2019/01/13.
//  Copyright © 2019 Tatsuhiro Aoshima. All rights reserved.
//

import UIKit

public typealias JoyStickViewMonitor = (_ x: CGFloat?, _ y: CGFloat?) -> ()

@IBDesignable public class JoystickView : UIView {
    public var monitor: JoyStickViewMonitor!

    var borderLayer: CAShapeLayer!
    var buttonLayer: CAShapeLayer!
    var borderRadius: CGFloat!
    var buttonRadius: CGFloat!

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    public override func layoutSubviews() {
        super.layoutSubviews()

        borderRadius = bounds.width*0.5
        buttonRadius = borderRadius*0.5

        borderLayer = CAShapeLayer.init()
        borderLayer.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)).cgPath
        borderLayer.fillColor = UIColor.init(white: 1.0, alpha: 0.2).cgColor
        layer.addSublayer(borderLayer)

        buttonLayer = CAShapeLayer.init()
        buttonLayer.fillColor = UIColor.white.cgColor
        layer.addSublayer(buttonLayer)
        moveTo()
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        moveTo()
    }
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchX = touch.location(in: self).x
            let touchY = touch.location(in: self).y
            moveTo(touchX: touchX, touchY: touchY)
        }
    }
    
    func moveTo(touchX: CGFloat? = nil, touchY: CGFloat? = nil) {
        let ended = touchX == nil || touchY == nil
        var x = (touchX ?? borderRadius) - borderRadius
        var y = (touchY ?? borderRadius) - borderRadius
        let r = sqrt(pow(x, 2.0) + pow(y, 2.0))
        if r > borderRadius - buttonRadius {
            let ratio = (borderRadius - buttonRadius)/r
            x = ratio*x
            y = ratio*y
        }
        buttonLayer.path = UIBezierPath(ovalIn: CGRect(x: x + borderRadius - buttonRadius, y: y + borderRadius - buttonRadius, width: 2.0*buttonRadius, height: 2.0*buttonRadius)).cgPath
        if ended {
            monitor?(nil, nil)
        } else {
            monitor?(x/borderRadius, y/borderRadius)
        }
    }
}
