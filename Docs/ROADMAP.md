# Project VICE roadmap

## Milestone 0 — Repository and build foundation
- [x] Create Unreal project descriptor and C++ module skeleton.
- [x] Add baseline character movement and perspective toggle.
- [x] Add initial iOS/mobile configuration.
- [ ] Verify project generation and compile against Unreal Engine 5.4 on macOS.

## Milestone 1 — Playable vertical slice
- [x] Create a procedural graybox city test district (production art and authored .umap still pending).
- [x] Add a controllable character, mobile virtual sticks, camera control, jump, sprint, and action HUD (graybox source implementation).
- [x] Add first-/third-person camera toggles for the character and vehicle (initial blockout camera; eye height and camera collision still need device tuning).
- [x] Add an arcade vehicle prototype with enter/exit, touch steering/throttle/brake, camera mode, and speed display (source implementation; not yet device-verified).
- [ ] Profile on iPhone 12 mini; tune thermal behavior and frame pacing.

## Milestone 2 — World streaming
- [ ] Establish a World Partition landscape and grid-based district layout.
- [ ] Define streaming sources around player and vehicle.
- [ ] Add HLOD, occlusion, distance culling, and asset budgets.
- [ ] Hide streaming transitions using overlap and sightline design.

## Milestone 3 — City simulation
- [x] Add a basic streamed sidewalk-pedestrian patrol prototype with distance-tiered update frequency.
- [ ] Modular road and building kits with original art direction.
- [x] Add sparse ambient road-loop traffic prototype with distance-tiered update frequency.
- [ ] Expand pedestrian behavior, add traffic lights, lane following, intersection logic, and traffic avoidance.
- [ ] Save/load, map, navigation, and mission framework.

## Milestone 4 — Environment and polish
- [x] Prototype a mobile-friendly time-of-day cycle for the map sun and sky light (device profiling and atmospheric polish pending).
- [ ] Weather presets and scalable effects.
- [ ] Audio, UI, accessibility, localization, and performance tiers.

## Visitor preview milestone
- [x] Add direct-to-game guest preview flow with on-screen visitor identity and touch hints.
- [x] Add reproducible map generation before iOS cooking.
- [x] Add a local signed iOS packaging script and a manual self-hosted macOS workflow.
- [ ] Compile with Unreal Engine 5.4 and package a signed Development/Ad Hoc IPA.
- [ ] Install and validate on iPhone 12 mini.

## Release gates
- [ ] No critical crashes in a 30-minute device session.
- [ ] Stable 30 FPS target under representative gameplay.
- [ ] Memory and thermal budgets validated on the baseline device.
- [ ] Signed, installable IPA produced through an authorized Apple development team.
