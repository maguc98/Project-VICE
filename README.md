# Project VICE

A mobile-first, original open-world action game targeting iPhone 12 mini, with a grounded modern coastal-city setting and a high-fidelity visual direction.

> Project VICE is an independent original project. It is not affiliated with Rockstar Games and does not use GTA or GTA VI assets, code, characters, maps, branding, or other proprietary material.

## Project goals

- Unreal Engine 5 C++ foundation for iOS.
- Original fictional coastal metropolis, built for continuous outdoor exploration.
- Third-person character controller with a first-/third-person camera mode.
- Vehicle driving and enter/exit flow.
- Streaming world cells, level-of-detail (LOD/HLOD), and memory-aware asset budgets.
- Touch-first mobile controls.
- Dynamic time-of-day and weather, introduced incrementally.
- iPhone 12 mini (A14, 4 GB RAM class) as the baseline performance target.

## Important scope and performance notes

A GTA-scale world and console-level GTA VI fidelity are not realistic on an iPhone 12 mini. This project targets the *visual language* of high-end photorealism while using mobile-appropriate geometry, materials, lighting, baked data, aggressive LOD, and streamed world cells. Initial performance target: stable 30 FPS, with dynamic resolution and quality tiers.

The outdoor world should feel continuous. Streaming boundaries must be hidden through overlap, occlusion, and asynchronous loading. Interior transitions may use short transitions where necessary.

## Repository status

This repository is being bootstrapped with source and configuration scaffolding. It does not yet contain Unreal Engine binaries, licensed marketplace assets, final character/vehicle art, or a signed IPA. Those require the Unreal Engine toolchain, art production, an Apple signing setup, and device testing.

## Getting started

1. Install a compatible Unreal Engine 5 version with iOS support on macOS.
2. Open `ProjectVICE.uproject` in Unreal Editor and allow project files to generate.
3. Generate Xcode project files if needed, install the matching Xcode/iOS SDK, and configure an Apple development team.
4. Build and deploy to a physical iPhone. The iOS Simulator is not a substitute for performance testing.

See [Docs/ROADMAP.md](Docs/ROADMAP.md), [Docs/TECHNICAL_DESIGN.md](Docs/TECHNICAL_DESIGN.md), [Docs/DEVICE_BUDGETS.md](Docs/DEVICE_BUDGETS.md), [Docs/MAP_SETUP.md](Docs/MAP_SETUP.md), [Docs/VEHICLE_PROTOTYPE.md](Docs/VEHICLE_PROTOTYPE.md), [Docs/ENVIRONMENT_PROTOTYPE.md](Docs/ENVIRONMENT_PROTOTYPE.md), [Docs/PEDESTRIAN_PROTOTYPE.md](Docs/PEDESTRIAN_PROTOTYPE.md), and [Docs/BUILD_STATUS.md](Docs/BUILD_STATUS.md).

The repository now includes a procedural streamed city-cell prototype, capsule-placeholder sidewalk pedestrians, character capsule placeholder, arcade sedan with enter/exit driving, native touch action HUD, and map bootstrap script. The map must be generated in Unreal Editor; source has not yet been compiled with Unreal Build Tool.

## License

No third-party game assets are included. Source licensing will be added once the project's distribution model is decided.
