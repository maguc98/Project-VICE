# Development roadmap

## M0 — Foundation
- [x] Repository reset and native app skeleton
- [x] Female reference measurement data model in centimetres
- [x] Interactive SceneKit viewport scaffold
- [ ] First CI build and simulator validation

## M1 — Female anatomical base mesh
- [x] One female reference figure; no male model or model selector
- [x] Continuous ring-built torso surface
- [x] Smooth interpolation between torso profile rings
- [x] Editable chest projection and posterior hip/gluteal projection
- [x] Named shoulder, elbow, knee, and ankle landmarks
- [x] Individually named finger and toe geometry blockout
- [ ] Refine anatomical landmarks, torso topology, and limb attachment transitions
- [ ] Validate front, side, and three-quarter silhouettes on device

## M2 — Rig and posing
- [x] Hierarchical shoulder and elbow pivot groups for both arms
- [ ] Full-body skeleton and joint constraints
- [x] Live shoulder raise and elbow bend controls
- [ ] IK/FK controls and individual finger articulation
- [ ] Pose library, mirror pose, reset, and local JSON save/load

## M3 — Artist tools
- [ ] Orbit/pan/zoom camera, focal length, orthographic view
- [ ] Anatomy overlays, lighting presets, silhouette and contour modes
- [ ] High-resolution transparent PNG export

## Performance targets
- iPhone 12 mini (A14) is the baseline device.
- Keep mesh rebuilds lightweight and avoid unnecessary scene recreation during slider movement.
- Offline operation; no account or network requirement for core modeling.
