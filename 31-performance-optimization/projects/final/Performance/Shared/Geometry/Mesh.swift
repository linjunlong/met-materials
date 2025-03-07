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

// swiftlint:disable force_unwrapping
// swiftlint:disable force_cast

struct Mesh {
  let vertexBuffers: [MTLBuffer]
  var submeshes: [Submesh]
  var transform: TransformComponent?
  let skeleton: Skeleton?
  var pipelineState: MTLRenderPipelineState
  var shadowPipelineState: MTLRenderPipelineState
}

extension Mesh {
  init(name: String, mdlMesh: MDLMesh, mtkMesh: MTKMesh) {
    let skeleton =
      Skeleton(animationBindComponent:
        (mdlMesh.componentConforming(to: MDLComponent.self)
        as? MDLAnimationBindComponent))
    self.skeleton = skeleton

    var vertexBuffers: [MTLBuffer] = []
    let labels = [
      "\(name) Position Buffer",
      "\(name) UV Buffer",
      "\(name) Color Buffer",
      "\(name) Tangent Buffer",
      "\(name) JointBuffer"
    ]
    for mtkMeshBuffer in mtkMesh.vertexBuffers {
      vertexBuffers.append(mtkMeshBuffer.buffer)
      let count = vertexBuffers.count - 1
      if count < 5 {
        vertexBuffers[count].label = labels[count]
      }
    }
    self.vertexBuffers = vertexBuffers
    submeshes = zip(mdlMesh.submeshes!, mtkMesh.submeshes).map { mesh in
      Submesh(mdlSubmesh: mesh.0 as! MDLSubmesh, mtkSubmesh: mesh.1)
    }
    let hasSkeleton = skeleton?.jointMatrixPaletteBuffer != nil
    pipelineState =
      PipelineStates.createForwardPSO(hasSkeleton: hasSkeleton)
    shadowPipelineState =
      PipelineStates.createShadowPSO(hasSkeleton: hasSkeleton)
  }

  init(
    name: String,
    mdlMesh: MDLMesh,
    mtkMesh: MTKMesh,
    startTime: TimeInterval,
    endTime: TimeInterval
  ) {
    self.init(name: name, mdlMesh: mdlMesh, mtkMesh: mtkMesh)
    if let mdlMeshTransform = mdlMesh.transform {
      transform = TransformComponent(
        transform: mdlMeshTransform,
        object: mdlMesh,
        startTime: startTime,
        endTime: endTime)
    } else {
      transform = nil
    }
  }
}
