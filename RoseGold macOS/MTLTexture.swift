//
//  MTLTexture.swift
//  RoseGold
//
//  Created by Tatsuhiro Aoshima on 2019/01/12.
//  Copyright © 2019 Tatsuhiro Aoshima. All rights reserved.
//

import Metal

extension MTLTexture {
    func imageData() -> UnsafeMutableRawPointer {
        let width = self.width
        let height = self.height
        let bytesPerRow = 4*width
        let data = malloc(4*width*height)!
        self.getBytes(data, bytesPerRow: bytesPerRow, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
        return data
    }
    func toImage() -> CGImage? {
        let width = self.width
        let height = self.height
        let imageBytes = 4*width*height
        let bytesPerRow = 4*width
        let data = imageData()
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let rawBitmapInfo = CGImageAlphaInfo.noneSkipFirst.rawValue|CGBitmapInfo.byteOrder32Little.rawValue
        let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: rawBitmapInfo)
        let releaseMaskImagePixelData: CGDataProviderReleaseDataCallback = { (info: UnsafeMutableRawPointer?, data: UnsafeRawPointer, size: Int) -> () in
            return
        }
        let provider = CGDataProvider(dataInfo: nil, data: data, size: imageBytes, releaseData: releaseMaskImagePixelData)
        let image = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo, provider: provider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)!
        return image
    }
}
