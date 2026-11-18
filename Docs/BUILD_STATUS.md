# Current build status

Last updated: 2026-11-18

## Implemented in source

- Unreal Engine 5.4 project descriptor and C++ runtime module.
- Game mode bootstrap that creates a player start and runtime city blockout.
- Procedural 7-by-7 road grid with primitive building masses.
- Character movement, jump, sprint, and first-/third-person camera toggle.
- Runtime touch HUD buttons for camera, jump, and sprint.
- Default mobile virtual joystick configuration for movement and camera look.
- Unreal Editor Python script to create the initial map with player start and basic lighting actors.
- GitHub Actions repository structure and Python syntax checks.

## Current prototype limitations

The city is a graybox made from engine primitive cubes, not a finished photorealistic environment. The player body is a capsule placeholder, not the final realistic character. There is no vehicle, NPC simulation, mission system, production animation, World Partition district content, or finished art/audio yet.

## Build and test status

The repository has **not** been compiled with Unreal Build Tool in this session and has **not** been launched on an iPhone. GitHub Actions checks project structure and Python syntax only; they do not compile Unreal C++.

The first map asset is generated locally by running the editor script described in [MAP_SETUP.md](MAP_SETUP.md). The iOS build still requires Unreal Engine with iOS support, Xcode, an Apple development team, and physical-device profiling.

## Next milestone

1. Run the editor bootstrap script and generate the map.
2. Compile the C++ module with Unreal Engine 5.4 and fix toolchain-reported issues.
3. Verify touch input and camera switching on an actual iPhone 12 mini.
4. Replace graybox body and buildings with original production assets.
5. Add a first drivable vehicle prototype and streamed district cells.
