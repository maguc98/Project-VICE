# Figure Studio · 人体工坊

Native iOS 3D female-figure reference studio for artists.

## Product direction
- A single female base figure; no male model or sex-selection flow.
- Realistic female proportions with an art-reference presentation (A3).
- Editable measurements in centimetres: stature, head, shoulders, chest/bust projection, waist, pelvis/gluteal projection, limbs, hands, and feet.
- Orbit camera, pose editing, anatomy layers, lighting, and PNG export.
- Offline-first; optimized for iPhone 12 mini (A14) and newer devices.

## Current model
The viewport uses a continuous ring-built torso with interpolated profile rings. Chest and posterior gluteal contours are shaped by localized deformation of that same surface. Limb segments, named joint landmarks, fingers, and toes form the current blockout. These are procedural study meshes, not a final production anatomical topology.

## Engineering
- SwiftUI for the native interface.
- SceneKit for the interactive 3D viewport (Metal-backed rendering).
- Parameterized body data is kept separate from rendering.
- XcodeGen generates the Xcode project from `project.yml`.

## Build
Install Xcode and XcodeGen, then run:

```sh
xcodegen generate
xcodebuild -project FigureStudio.xcodeproj -scheme FigureStudio -destination 'generic/platform=iOS Simulator' build
```
