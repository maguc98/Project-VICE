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

The project now has a direct-to-game guest flow and an explicitly labelled **Project VICE — 游客预览版** HUD. It remains a graybox engineering preview: it does not yet contain final character/vehicle art or a signed IPA. A local macOS iOS packaging script and a manually triggered self-hosted GitHub Actions workflow are provided; both require Unreal Engine 5.4, Xcode, and valid Apple signing assets on the build machine.

## Getting started

1. Install a compatible Unreal Engine 5 version with iOS support on macOS.
2. Open `ProjectVICE.uproject` in Unreal Editor and allow project files to generate.
3. Generate Xcode project files if needed, install the matching Xcode/iOS SDK, and configure an Apple development team.
4. Build and deploy to a physical iPhone. The iOS Simulator is not a substitute for performance testing.

See [Docs/ROADMAP.md](Docs/ROADMAP.md), [Docs/TECHNICAL_DESIGN.md](Docs/TECHNICAL_DESIGN.md), [Docs/DEVICE_BUDGETS.md](Docs/DEVICE_BUDGETS.md), [Docs/MAP_SETUP.md](Docs/MAP_SETUP.md), [Docs/VEHICLE_PROTOTYPE.md](Docs/VEHICLE_PROTOTYPE.md), [Docs/ENVIRONMENT_PROTOTYPE.md](Docs/ENVIRONMENT_PROTOTYPE.md), [Docs/PEDESTRIAN_PROTOTYPE.md](Docs/PEDESTRIAN_PROTOTYPE.md), [Docs/TRAFFIC_PROTOTYPE.md](Docs/TRAFFIC_PROTOTYPE.md), [Docs/CITY_VISUAL_STYLE.md](Docs/CITY_VISUAL_STYLE.md), and [Docs/BUILD_STATUS.md](Docs/BUILD_STATUS.md).

The repository includes a streamed coastal-city graybox with material-separated streets, connected sidewalks, road markings, facade details and low-poly trees; capsule-placeholder pedestrians, sparse ambient road-loop traffic, a character capsule placeholder, arcade sedan with enter/exit driving, native touch action HUD, visitor-preview guidance, and a map bootstrap script. The iOS build workflow generates the map before cooking; source has not yet been compiled with Unreal Build Tool. See [iOS Visitor Preview](Docs/IOS_VISITOR_PREVIEW.md) for the build requirements.

## License

No third-party game assets are included. Source licensing will be added once the project's distribution model is decided.
