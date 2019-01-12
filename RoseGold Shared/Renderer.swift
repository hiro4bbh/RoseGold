//
//  Renderer.swift
//  RoseGold
//
//  Created by Tatsuhiro Aoshima on 2019/01/10.
//  Copyright © 2019 Tatsuhiro Aoshima. All rights reserved.
//

// Our platform independent renderer class

import Metal
import MetalKit
import simd

let maxBuffersInFlight = 3

class Renderer: NSObject, MTKViewDelegate {
    public let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var computePipelineState: MTLComputePipelineState
    var renderPipelineState: MTLRenderPipelineState
    var depthState: MTLDepthStencilState

    let inFlightSemaphore = DispatchSemaphore(value: maxBuffersInFlight)
    
    var viewportSize: uint2
    var environmentBuffer: MTLBuffer
    var environment: UnsafeMutablePointer<Environment>
    let startTime: TimeInterval
    var lastReportTime: TimeInterval
    var lastReportNrun: Float
    var outputTexture: MTLTexture
    let threadGroupSize: MTLSize
    let threadGroupCount: MTLSize

    init?(metalKitView: MTKView) {
        device = metalKitView.device!
        commandQueue = device.makeCommandQueue()!

        metalKitView.depthStencilPixelFormat = MTLPixelFormat.depth32Float_stencil8
        metalKitView.colorPixelFormat = MTLPixelFormat.bgra8Unorm_srgb
        metalKitView.sampleCount = 1

        let mtlVertexDescriptor = Renderer.buildMetalVertexDescriptor()

        do {
            computePipelineState = try Renderer.buildComputePipelineWithDevice(device: device)
        } catch {
            print("Unable to compile compute pipeline state.  Error info: \(error)")
            return nil
        }
        do {
            renderPipelineState = try Renderer.buildRenderPipelineWithDevice(device: device,
                                                                            metalKitView: metalKitView,
                                                                            mtlVertexDescriptor: mtlVertexDescriptor)
        } catch {
            print("Unable to compile render pipeline state.  Error info: \(error)")
            return nil
        }

        let depthStateDesciptor = MTLDepthStencilDescriptor()
        depthStateDesciptor.depthCompareFunction = MTLCompareFunction.less
        depthStateDesciptor.isDepthWriteEnabled = true
        depthState = device.makeDepthStencilState(descriptor:depthStateDesciptor)!

        viewportSize = uint2(0, 0)
        environmentBuffer = device.makeBuffer(length: MemoryLayout<Environment>.size, options: MTLResourceOptions.init(rawValue: 0))!
        environmentBuffer.label = "Environment Buffer"
        environment = UnsafeMutableRawPointer(environmentBuffer.contents()).bindMemory(to:Environment.self, capacity:1)
        startTime = NSDate().timeIntervalSince1970
        lastReportTime = startTime
        lastReportNrun = 0

        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.bgra8Unorm, width: 1024, height: 1024, mipmapped: false)
        textureDescriptor.usage = MTLTextureUsage.init(rawValue: MTLTextureUsage.shaderRead.rawValue|MTLTextureUsage.shaderWrite.rawValue)
        outputTexture = device.makeTexture(descriptor: textureDescriptor)!

        // Set the compute kernel's threadgroup size of 16x16
        threadGroupSize = MTLSize.init(width: 16, height: 16, depth: 1);
        // Calculate the number of rows and columns of threadgroups given the width of the input image
        // Ensure that you cover the entire image (or more) so you process every pixel
        // Since we're only dealing with a 2D data set, set depth to 1
        threadGroupCount = MTLSize.init(width: (outputTexture.width  + threadGroupSize.width -  1)/threadGroupSize.width,
                                        height: (outputTexture.height + threadGroupSize.height - 1)/threadGroupSize.height,
                                        depth: 1)
        
        super.init()

    }

    class func buildMetalVertexDescriptor() -> MTLVertexDescriptor {
        let mtlVertexDescriptor = MTLVertexDescriptor()

        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].format = MTLVertexFormat.float2
        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].offset = 0
        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].bufferIndex = BufferIndex.vertices.rawValue

        mtlVertexDescriptor.attributes[VertexAttribute.texcoord.rawValue].format = MTLVertexFormat.float2
        mtlVertexDescriptor.attributes[VertexAttribute.texcoord.rawValue].offset = 0
        mtlVertexDescriptor.attributes[VertexAttribute.texcoord.rawValue].bufferIndex = BufferIndex.viewpointSize.rawValue

        mtlVertexDescriptor.layouts[BufferIndex.vertices.rawValue].stride = 8
        mtlVertexDescriptor.layouts[BufferIndex.vertices.rawValue].stepRate = 1
        mtlVertexDescriptor.layouts[BufferIndex.vertices.rawValue].stepFunction = MTLVertexStepFunction.perVertex

        mtlVertexDescriptor.layouts[BufferIndex.viewpointSize.rawValue].stride = 8
        mtlVertexDescriptor.layouts[BufferIndex.viewpointSize.rawValue].stepRate = 1
        mtlVertexDescriptor.layouts[BufferIndex.viewpointSize.rawValue].stepFunction = MTLVertexStepFunction.perVertex

        return mtlVertexDescriptor
    }

    class func buildComputePipelineWithDevice(device: MTLDevice) throws -> MTLComputePipelineState {
        let library = device.makeDefaultLibrary()!
        let kernelFunction = library.makeFunction(name: "roseGoldKernel")!
        return try device.makeComputePipelineState(function: kernelFunction)
    }

    class func buildRenderPipelineWithDevice(device: MTLDevice,
                                             metalKitView: MTKView,
                                             mtlVertexDescriptor: MTLVertexDescriptor) throws -> MTLRenderPipelineState {
        /// Build a render state pipeline object
        let library = device.makeDefaultLibrary()!
        let vertexFunction = library.makeFunction(name: "vertexShader")
        let fragmentFunction = library.makeFunction(name: "fragmentShader")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "RenderPipeline"
        pipelineDescriptor.sampleCount = metalKitView.sampleCount
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = mtlVertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        pipelineDescriptor.stencilAttachmentPixelFormat = metalKitView.depthStencilPixelFormat

        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }

    func draw(in view: MTKView) {
        let halfSize = Float(viewportSize.min()!)/2.0;
        let quadVertices: Array<Vertex> = [
            /// Pixel Positions, Texture Coordinates
            Vertex(position: float2( halfSize, -halfSize), texCoord: float2(1.0, 0.0)),
            Vertex(position: float2(-halfSize, -halfSize), texCoord: float2(0.0, 0.0)),
            Vertex(position: float2(-halfSize,  halfSize), texCoord: float2(0.0, 1.0)),
            
            Vertex(position: float2( halfSize, -halfSize), texCoord: float2(1.0, 0.0)),
            Vertex(position: float2(-halfSize,  halfSize), texCoord: float2(0.0, 1.0)),
            Vertex(position: float2( halfSize,  halfSize), texCoord: float2(1.0, 1.0)),
        ];
        /// Per frame updates hare
        _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
        environment[0].nrun += 1;
        environment[0].timestamp = Float(NSDate().timeIntervalSince1970 - startTime)

        if let commandBuffer = commandQueue.makeCommandBuffer() {
            let semaphore = inFlightSemaphore
            commandBuffer.addCompletedHandler { (_ commandBuffer)-> Swift.Void in
                DispatchQueue.main.async {
                    let now = NSDate().timeIntervalSince1970
                    let dtime = now - self.lastReportTime
                    if dtime >= 1.0 {
                        let dnrun = self.environment[0].nrun - self.lastReportNrun
                        print(String(format: "ts=%.3f: %.1f fps (total %.0f frames)", self.environment[0].timestamp, dnrun/Float(dtime), self.environment[0].nrun))
                        self.lastReportTime = now
                        self.lastReportNrun = self.environment[0].nrun
                    }
                }
                semaphore.signal()
            }
            
            // Run the compute shader.
            if let computeEncoder = commandBuffer.makeComputeCommandEncoder() {
                computeEncoder.setComputePipelineState(computePipelineState)
                computeEncoder.setBuffer(environmentBuffer, offset: 0, index: BufferIndex.environment.rawValue)
                computeEncoder.setTexture(outputTexture, index: TextureIndex.output.rawValue)
                computeEncoder.dispatchThreadgroups(threadGroupCount, threadsPerThreadgroup: threadGroupSize)
                computeEncoder.endEncoding()
            }
 
            /// Delay getting the currentRenderPassDescriptor until we absolutely need it to avoid
            ///   holding onto the drawable and blocking the display pipeline any longer than necessary
            if let renderPassDescriptor = view.currentRenderPassDescriptor {
                /// Final pass rendering code here
                if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                    renderEncoder.label = "Primary Render Encoder"

                    renderEncoder.pushDebugGroup("Draw Box")
                    renderEncoder.setRenderPipelineState(renderPipelineState)
                    renderEncoder.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(viewportSize.x), height: Double(viewportSize.y), znear: -1.0, zfar: 1.0))
                    renderEncoder.setVertexBytes(quadVertices, length: quadVertices.count*MemoryLayout<Vertex>.size, index: BufferIndex.vertices.rawValue)
                    renderEncoder.setVertexBytes(&viewportSize, length: MemoryLayout<uint2>.size, index: BufferIndex.viewpointSize.rawValue)
                    renderEncoder.setFragmentTexture(outputTexture, index: TextureIndex.output.rawValue)
                    renderEncoder.drawPrimitives(type: MTLPrimitiveType.triangle, vertexStart: 0, vertexCount: 6)
                    renderEncoder.popDebugGroup()

                    renderEncoder.endEncoding()
                    
                    if let drawable = view.currentDrawable {
                        commandBuffer.present(drawable)
                    }
                }
            }

            commandBuffer.commit()
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        /// Respond to drawable size or orientation changes here
        viewportSize.x = UInt32(size.width)
        viewportSize.y = UInt32(size.height)
    }
}
