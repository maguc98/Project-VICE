# Development roadmap

## M0 — Foundation
- [x] Repository reset and native app skeleton
- [x] Measurement data model in centimetres
- [x] Interactive SceneKit viewport scaffold
- [ ] First CI build and simulator validation

## M1 — Anatomical base mesh
- Replace primitive proportion volumes with connected, smooth human topology.
- Separate male/female base profiles while keeping shared measurement semantics.
- Implement measurement-driven deformation with silhouette and landmark constraints.
- Validate proportions from front, side, and three-quarter views.

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
