import Foundation
import SceneKit
import GLTFKit2

/// Loads the bundled, offline female anatomical base mesh.
enum FemaleBaseMeshLoader {
    private static var retainedAsset: GLTFAsset?
    private static var cachedScene: SCNScene?
    private static var isLoading = false
    private static var pendingCompletions: [(SCNScene?) -> Void] = []

    static func load(completion: @escaping (SCNScene?) -> Void) {
        if let cachedScene {
            completion(cachedScene)
            return
        }
        pendingCompletions.append(completion)
        guard !isLoading else { return }
        isLoading = true

        guard let url = Bundle.main.url(forResource: "FemaleBase", withExtension: "glb") else {
            finish(nil)
            return
        }

        GLTFAsset.load(with: url, options: [:]) { _, status, maybeAsset, maybeError, _ in
            guard status == .complete, let asset = maybeAsset else {
                if let maybeError {
                    NSLog("Female base mesh load failed: %@", maybeError.localizedDescription)
                }
                DispatchQueue.main.async { finish(nil) }
                return
            }

            let source = GLTFSCNSceneSource(asset: asset)
            let scene = source.defaultScene
            DispatchQueue.main.async {
                retainedAsset = asset
                finish(scene)
            }
        }
    }

    private static func finish(_ scene: SCNScene?) {
        cachedScene = scene
        isLoading = false
        let completions = pendingCompletions
        pendingCompletions.removeAll()
        completions.forEach { $0(scene) }
    }
}
