# Figure Studio · 人体工坊

Native iOS 3D female-figure reference studio for artists.

## Product direction
- Female figure only; no male model or sex-selection flow.
- Anatomical reference model with editable proportions and a full-body posing workflow.
- Measurements are presented in centimetres.
- Orbit camera, FK/IK posing, individually adjustable finger joints, named pose library, lighting and high-resolution PNG export.
- The bundled base model works offline after installation; the build downloads the licensed model asset at build time.
- iPhone 12 mini (A14) is the baseline performance target.

## Realistic base model and license
The current default base is the **Female Base Mesh — 3D Person, Rigged A-Pose** from Innerscene, distributed under **CC0 1.0 Universal**. The model is bundled as `Resources/FemaleBase.glb` and loaded locally with GLTFKit2. Its MakeHuman-style skin rig includes spine, bilateral arms and legs, individual fingers and toes.

The model is an anatomical 3D base mesh, not a photographic scan or a medically validated anatomy model. The app currently applies global stature/width/depth proportion scaling; detailed local morph controls for bust, waist, pelvis and limb circumference still require a dedicated morph-target pass.

## Current implementation
- SwiftUI interface with measurement, pose, rendering and export sections.
- SceneKit viewport with orbit/zoom, PBR skin material, studio/soft/dramatic lighting, silhouette, wireframe and skeleton-oriented views.
- FK controls for torso, left/right shoulders, elbows, wrists, five fingers per hand, hips, knees, ankles and toes.
- IK target controls for left/right hands and feet.
- Presets: natural, A-pose, walking, sitting and squat; mirror, save, load and delete named poses locally.
- High-resolution 1800×2400 PNG share/export.
- Procedural model remains as a fallback if the offline GLB cannot load.

## Engineering
- SwiftUI for the native interface.
- SceneKit for interactive 3D rendering.
- GLTFKit2 for loading the rigged GLB model.
- XcodeGen generates the Xcode project from `project.yml`.

## Build
GitHub Actions performs iOS Simulator build, device archive and unsigned IPA packaging on pushes to `main` and manual runs.

1. Open the repository's Actions page.
2. Open the latest successful **iOS Build** run.
3. Download the `figure-studio-unsigned-ipa` artifact and extract the ZIP to get `FigureStudio-unsigned.ipa`.
4. Sign the IPA with your own certificate and provisioning profile before installing it on a device.

The IPA is unsigned and must be signed before installation. Pull-request runs only perform the simulator build.
