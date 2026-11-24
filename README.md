# Figure Studio · 人体工坊

Native iOS 3D female-figure reference studio for artists.

## Product direction
- A single female base figure; no male model or sex-selection flow.
- Realistic female anatomy and proportions with an art-reference presentation (A3).
- Editable measurements in centimetres: stature, head, torso, pelvis, limbs, hands, and feet.
- Orbit camera, pose editing, anatomy layers, lighting, and PNG export.
- Offline-first; optimized for iPhone 12 mini (A14) and newer devices.

The default dimensions are a starting reference, not a restriction. The user can adjust the figure across the supported measurement ranges.

## Engineering
- SwiftUI for the native interface.
- SceneKit for the first interactive 3D viewport (Metal-backed rendering).
- Parameterized body data is kept separate from rendering so the anatomical mesh system can evolve.
- XcodeGen generates the Xcode project from `project.yml`.

## Current milestone
**Milestone 0 — foundation:** app shell, female reference measurement defaults, initial viewport scaffold, and CI build workflow.

The current viewport now uses a continuous ring-built torso surface and proportion-driven tapered limb segments. This is an early anatomical blockout, not a finished anatomical model: hands, feet, head, and limb joints are still simplified, and the torso topology still needs anatomical refinement.

## Build
Install Xcode and XcodeGen, then run:

```sh
xcodegen generate
xcodebuild -project FigureStudio.xcodeproj -scheme FigureStudio -destination 'generic/platform=iOS Simulator' build
```
