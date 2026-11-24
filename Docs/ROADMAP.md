# Development roadmap

## M0 — Foundation
- [x] Repository reset and native app skeleton
- [x] Female reference measurement data model in centimetres
- [x] Interactive SceneKit viewport scaffold
- [ ] First CI build and simulator validation

## M1 — Female anatomical base mesh
- [x] Establish one female reference figure; no male model or model selector.
- [x] Replace the torso's separate primitive volumes with a continuous ring-built surface.
- [x] Drive torso silhouette and limb segment lengths from editable measurements.
- [ ] Refine torso landmarks, breast/chest transition, shoulder, pelvis, knees, and ankles.
- [ ] Replace simplified head, hands, feet, and limb joints with anatomical forms.
- [ ] Validate proportions from front, side, and three-quarter views.

## M2 — Rig and posing
- Hierarchical skeleton, IK/FK controls, hand and finger controls.
- Pose library, mirror pose, reset, and local JSON save/load.

## M3 — Artist tools
- Orbit/pan/zoom camera, focal length, orthographic view.
- Anatomy overlays, lighting presets, silhouette and contour modes.
- High-resolution transparent PNG export.

## Performance targets
- iPhone 12 mini (A14) is the baseline device.
- Keep model updates incremental; avoid rebuilding the full scene for every slider tick.
- Offline operation; no account or network requirement for core modeling.
