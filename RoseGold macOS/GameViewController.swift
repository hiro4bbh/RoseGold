//
//  GameViewController.swift
//  RoseGold macOS
//
//  Created by Tatsuhiro Aoshima on 2019/01/12.
//  Copyright © 2019 Tatsuhiro Aoshima. All rights reserved.
//

import Cocoa
import MetalKit

// Our macOS specific view controller
class GameViewController: NSViewController {
    var renderer: Renderer!
    var mtkView: MTKView!

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let mtkView = self.view as? MTKView else {
            print("View attached to GameViewController is not an MTKView")
            return
        }
        // Select the device to render with.  We choose the default device
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device")
            return
        }
        mtkView.device = defaultDevice

        guard let newRenderer = Renderer(metalKitView: mtkView) else {
            print("Renderer cannot be initialized")
            return
        }
        renderer = newRenderer
        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
        mtkView.delegate = renderer
    }
    
    @IBAction func resetImage(_ sender: NSMenuItem) {
        renderer.resetTexture()
    }
    @IBAction func turnCameraLeft(_ sender: NSMenuItem) {
        renderer.turnCameraToward(delta: float2(-Float.pi/8.0, 0.0))
    }
    @IBAction func turnCameraRight(_ sender: NSMenuItem) {
        renderer.turnCameraToward(delta: float2(Float.pi/8.0, 0.0))
    }
    @IBAction func saveImage(_ sender: NSMenuItem) {
        var path = FileManager.default.homeDirectoryForCurrentUser
        path.appendPathComponent("Desktop")
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss"
        print(dateFormatter.string(from: NSDate() as Date))
        let filename = String(format: "RoseGold-%@-%.0f.png", dateFormatter.string(from: NSDate() as Date), renderer.nframe)
        path.appendPathComponent(filename)
        print("Dumping current image to \(filename) ...")
        let texture = renderer.texture
        if let imageRef = texture.toImage() {
            let image: NSImage = NSImage.init(cgImage: imageRef, size: NSSize.init(width: imageRef.width, height: imageRef.height))
            do {
                try image.tiffRepresentation?.write(to: path)
            } catch {
                print(error)
            }
        }
    }
    @IBAction func stepCameraBackward(_ sender: NSMenuItem) {
        renderer.moveCameraToward(delta: float3(0.0, 0.0, -5.0))
    }
    @IBAction func stepCameraToward(_ sender: NSMenuItem) {
        renderer.moveCameraToward(delta: float3(0.0, 0.0, 5.0))
    }
}
