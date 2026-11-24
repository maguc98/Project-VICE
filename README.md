# Figure Studio · 人体工坊

Native iOS 3D female-figure reference studio for artists.

## Product direction
- A single female base figure; no male model or sex-selection flow.
- Realistic female proportions with an art-reference presentation (A3).
- Editable measurements in centimetres: stature, head, shoulders, chest/bust projection, waist, pelvis/gluteal projection, limbs, hands, and feet.
- Orbit camera, initial live shoulder/elbow posing controls, anatomy layers, lighting, and PNG export.
- Offline-first; optimized for iPhone 12 mini (A14) and newer devices.

## Current model
The viewport uses a continuous ring-built torso with interpolated profile rings. Chest and posterior gluteal contours are shaped by localized deformation of that same surface. Limb segments, named shoulder/elbow/knee/ankle landmarks, individually named fingers, and toe forms complete the current blockout. Chest projection and gluteal projection are separately adjustable. These are procedural study meshes, not a final production anatomical topology.

## Engineering
- SwiftUI for the native interface.
- SceneKit for the interactive 3D viewport (Metal-backed rendering).
- Parameterized body data is kept separate from rendering.
- XcodeGen generates the Xcode project from `project.yml`.

## Build
The GitHub Actions workflow builds the iOS Simulator target and, on pushes to `main` or manual runs, creates an **unsigned device IPA** as a workflow artifact.

1. Open the repository's Actions page.
2. Open the latest successful **iOS Build** run.
3. Download the `figure-studio-unsigned-ipa` artifact and extract the ZIP to get `FigureStudio-unsigned.ipa`.
4. Sign the IPA with your own certificate and provisioning profile before installing it on a device.

The IPA is deliberately unsigned; it is not directly installable until signed. Pull-request runs only perform the simulator build.

For a local simulator build:

```sh
xcodegen generate
xcodebuild -project FigureStudio.xcodeproj -scheme FigureStudio -destination 'generic/platform=iOS Simulator' build
```
