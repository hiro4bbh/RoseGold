//
//  GameViewController.swift
//  RoseGold iOS
//
//  Created by Tatsuhiro Aoshima on 2019/01/12.
//  Copyright © 2019 Tatsuhiro Aoshima. All rights reserved.
//

import UIKit
import MetalKit

// Our iOS specific view controller
class GameViewController: UIViewController {
    var renderer: Renderer!
    var mtkView: MTKView!
    @IBOutlet var joystickView: JoystickView!
    private var joystick: float2!

    override func viewDidLoad() {
        super.viewDidLoad()
        mtkView = self.view as? MTKView
        if mtkView == nil {
            print("View of Gameview controller is not an MTKView")
            return
        }
        // Select the device to render with.  We choose the default device
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported")
            return
        }
        mtkView.device = defaultDevice
        mtkView.backgroundColor = UIColor.black

        guard let newRenderer = Renderer(metalKitView: mtkView) else {
            print("Renderer cannot be initialized")
            return
        }
        renderer = newRenderer
        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
        mtkView.delegate = renderer
        
        let joystickMonitor: JoyStickViewMonitor = { x, y in
            if x == nil || y == nil {
                self.renderer.accelCamera()
            } else {
                self.renderer.accelCamera(5.0*float2(Float(x!), -Float(y!)))
            }
        }
        joystickView.monitor = joystickMonitor
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            if touch.view != mtkView {
                return
            }
            let touchX = touch.location(in: mtkView).x
            let touchX0 = touch.previousLocation(in: mtkView).x
            let touchY = touch.location(in: mtkView).y
            let touchY0 = touch.previousLocation(in: mtkView).y
            let angleX = (touchX - touchX0)*UIScreen.main.scale/UIScreen.main.bounds.width
            let angleY = (touchY - touchY0)*UIScreen.main.scale/UIScreen.main.bounds.height*0.25
            renderer.accelCameraDirection(float2(Float(angleX), -Float(angleY))*Float.pi)
            renderer.accelCameraDirection()
        }
    }
}
