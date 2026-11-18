# Project VICE roadmap

## Milestone 0 — Repository and build foundation
- [x] Create Unreal project descriptor and C++ module skeleton.
- [x] Add baseline character movement and perspective toggle.
- [x] Add initial iOS/mobile configuration.
- [ ] Verify project generation and compile against the selected Unreal Engine version on macOS.

## Milestone 1 — Playable vertical slice
- [ ] Create a small original coastal-city test district.
- [ ] Add a controllable third-person character and touch HUD (virtual stick, camera drag, jump, interact).
- [ ] Add first-person camera with correct eye height, collision, and animation handling.
- [ ] Add one drivable vehicle with enter/exit and a mobile-friendly driving HUD.
- [ ] Profile on iPhone 12 mini; tune thermal behavior and frame pacing.

## Milestone 2 — World streaming
- [ ] Establish a World Partition landscape and grid-based district layout.
- [ ] Define streaming sources around player and vehicle.
- [ ] Add HLOD, occlusion, distance culling, and asset budgets.
- [ ] Hide streaming transitions using overlap and sightline design.

## Milestone 3 — City simulation
- [ ] Modular road and building kits with original art direction.
- [ ] Lightweight pedestrian and traffic simulation with distance-based update rates.
- [ ] Save/load, map, navigation, and mission framework.

## Milestone 4 — Environment and polish
- [ ] Time-of-day system with mobile-friendly lighting.
- [ ] Weather presets and scalable effects.
- [ ] Audio, UI, accessibility, localization, and performance tiers.

## Release gates
- [ ] No critical crashes in a 30-minute device session.
- [ ] Stable 30 FPS target under representative gameplay.
- [ ] Memory and thermal budgets validated on the baseline device.
- [ ] Signed, installable IPA produced through an authorized Apple development team.
