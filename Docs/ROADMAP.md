# Development roadmap

## M0 — Foundation
- [x] Native iOS app shell and XcodeGen project
- [x] Female-only reference profile and centimetre measurement model
- [x] SceneKit orbit viewport and offline rendering pipeline
- [x] CI simulator build, device archive and unsigned IPA artifact

## M1 — Realistic female base
- [x] Bundle licensed CC0 rigged female GLB model
- [x] Load the base mesh offline with GLTFKit2
- [x] Use its skin-weighted skeleton in the viewport
- [x] Retain procedural figure as fallback
- [ ] Local morph targets for bust, waist, pelvis/gluteal volume and limb circumference
- [ ] Validate natural body shape, joint deformations and front/side/rear silhouettes on iPhone

## M2 — Full-body rig and posing
- [x] Independent left/right shoulder, elbow, forearm and wrist controls
- [x] Individual finger curl controls for both hands
- [x] Independent hip, knee, ankle and toe controls
- [x] FK/IK target modes for arms and legs
- [x] Spine and head posing
- [x] Pose presets, mirror, named local save/load/delete
- [ ] Validate joint axes, ranges and skinning deformation on physical device
- [ ] Improve reach limits and joint constraints using measured bind-pose lengths

## M3 — Artist tools
- [x] PBR presentation and studio/soft/dramatic lighting choices
- [x] Silhouette and wireframe display modes
- [x] High-resolution 1800×2400 PNG export
- [ ] Dynamic skeleton/bone overlay and anatomical landmark guides
- [ ] Dedicated orthographic front/side/back camera presets
- [ ] Optional transparent background and clean image crop presets

## M4 — Performance and quality
- [ ] Profile on iPhone 12 mini (A14), optimize draw calls and memory
- [ ] Smooth pose transitions and keyframe capture
- [ ] Local geometry morph sliders for all requested body measurements
- [ ] Final visual QA for front, profile, back, hands and feet
- [ ] Signed device IPA and installation test on iPhone 12 mini

## Constraints
- The CC0 base mesh is a reusable anatomical reference model, not a photographic scan or medical model.
- A successful CI archive proves compilation and packaging, not that every movement looks correct on a physical device.
- The final distribution artifact is unsigned; it must be signed with the user's own certificate/profile.
