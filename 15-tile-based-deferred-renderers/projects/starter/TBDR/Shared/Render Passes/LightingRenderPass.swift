/// Copyright (c) 2022 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import MetalKit

struct LightingRenderPass: RenderPass {
  let label = "Lighting Render Pass"
  var descriptor: MTLRenderPassDescriptor?
  var sunLightPSO: MTLRenderPipelineState
  var pointLightPSO: MTLRenderPipelineState
  let depthStencilState: MTLDepthStencilState?
  weak var albedoTexture: MTLTexture?
  weak var normalTexture: MTLTexture?
  weak var positionTexture: MTLTexture?
  var icosphere = Model(name: "icosphere.obj")

  init(view: MTKView) {
    sunLightPSO = PipelineStates.createSunLightPSO(
      colorPixelFormat: view.colorPixelFormat)
    pointLightPSO = PipelineStates.createPointLightPSO(
      colorPixelFormat: view.colorPixelFormat)
    depthStencilState = Self.buildDepthStencilState()
  }

  static func buildDepthStencilState() -> MTLDepthStencilState? {
    let descriptor = MTLDepthStencilDescriptor()
    descriptor.isDepthWriteEnabled = false
    return Renderer.device.makeDepthStencilState(descriptor: descriptor)
  }

  func resize(view: MTKView, size: CGSize) {}

  func drawSunLight(
    renderEncoder: MTLRenderCommandEncoder,
    scene: GameScene,
    params: Params
  ) {
    renderEncoder.pushDebugGroup("Sun Light")
    renderEncoder.setRenderPipelineState(sunLightPSO)
    var params = params
    params.lightCount = UInt32(scene.lighting.sunlights.count)
    renderEncoder.setFragmentBytes(
      &params,
      length: MemoryLayout<Params>.stride,
      index: ParamsBuffer.index)
    renderEncoder.setFragmentBuffer(
      scene.lighting.sunBuffer,
      offset: 0,
      index: LightBuffer.index)
    renderEncoder.drawPrimitives(
      type: .triangle,
      vertexStart: 0,
      vertexCount: 6)
    renderEncoder.popDebugGroup()
  }

  func drawPointLight(
    renderEncoder: MTLRenderCommandEncoder,
    scene: GameScene,
    params: Params
  ) {
    renderEncoder.pushDebugGroup("Point lights")
    renderEncoder.setRenderPipelineState(pointLightPSO)
    renderEncoder.setVertexBuffer(
      scene.lighting.pointBuffer,
      offset: 0,
      index: LightBuffer.index)
    renderEncoder.setFragmentBuffer(
      scene.lighting.pointBuffer,
      offset: 0,
      index: LightBuffer.index)
    guard let mesh = icosphere.meshes.first,
      let submesh = mesh.submeshes.first else { return }
    for (index, vertexBuffer) in mesh.vertexBuffers.enumerated() {
      renderEncoder.setVertexBuffer(
        vertexBuffer,
        offset: 0,
        index: index)
    }
    renderEncoder.drawIndexedPrimitives(
      type: .triangle,
      indexCount: submesh.indexCount,
      indexType: submesh.indexType,
      indexBuffer: submesh.indexBuffer,
      indexBufferOffset: submesh.indexBufferOffset,
      instanceCount: scene.lighting.pointLights.count)
    renderEncoder.popDebugGroup()
  }

  func draw(
    commandBuffer: MTLCommandBuffer,
    scene: GameScene,
    uniforms: Uniforms,
    params: Params
  ) {
    guard let descriptor = descriptor,
      let renderEncoder =
        commandBuffer.makeRenderCommandEncoder(
        descriptor: descriptor) else {
          return
    }
    renderEncoder.label = label
    renderEncoder.setDepthStencilState(depthStencilState)
    var uniforms = uniforms
    renderEncoder.setVertexBytes(
      &uniforms,
      length: MemoryLayout<Uniforms>.stride,
      index: UniformsBuffer.index)
    renderEncoder.setFragmentTexture(
      albedoTexture,
      index: BaseColor.index)
    renderEncoder.setFragmentTexture(
      normalTexture,
      index: NormalTexture.index)
    renderEncoder.setFragmentTexture(
      positionTexture, index: NormalTexture.index + 1)
    drawSunLight(
      renderEncoder: renderEncoder,
      scene: scene,
      params: params)
    drawPointLight(
      renderEncoder: renderEncoder,
      scene: scene,
      params: params)
    renderEncoder.endEncoding()
  }
}
