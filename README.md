# Figure Studio · 人体工坊

Native iOS 3D figure-reference studio for artists. The repository has been reset and is now the home of Figure Studio.

## Product direction
- Realistic human proportions with an art-reference presentation (A3).
- Male and female body profiles, with editable measurements in centimetres.
- Adjustable stature, head, torso, pelvis, limbs, hands, and feet.
- Orbit camera, pose editing, anatomy layers, lighting, and PNG export.
- Offline-first; optimized for iPhone 12 mini (A14) and newer devices.

## Engineering
- SwiftUI for the native interface.
- SceneKit for the first interactive 3D viewport (Metal-backed rendering).
- Parameterized body data is kept separate from rendering so the mesh system can evolve.
- XcodeGen generates the Xcode project from `project.yml`.

## Current milestone
**Milestone 0 — foundation:** app shell, measurement model, initial viewport scaffold, and CI build workflow.

The initial viewport is a proportion-study scaffold, not a finished anatomical model. Anatomical-quality topology and deformation are planned as the next milestone.

## Build
Install Xcode and XcodeGen, then run:

```sh
xcodegen generate
xcodebuild -project FigureStudio.xcodeproj -scheme FigureStudio -destination 'generic/platform=iOS Simulator' build
```
