# Current build status

Last updated: 2026-11-18

## Implemented in source

- Unreal Engine 5.4 project descriptor, runtime module, and correctly named game/editor target files.
- Game mode bootstrap that creates the player start, graybox city, and first vehicle.
- Procedural 7-by-7 road grid with primitive building masses.
- Character movement, jump, sprint, and first-/third-person camera toggle.
- Runtime mobile touch HUD with camera, jump, sprint, vehicle interaction, and brake buttons.
- Default virtual joystick axes mapped for movement, driving, and camera look.
- Arcade sedan prototype with throttle, reverse, steering, swept collision, camera toggle, enter/exit possession flow, and speed readout.
- Unreal Editor Python script to create the initial map with player start and basic lighting actors.
- GitHub Actions repository structure and Python syntax checks.

## Current prototype limitations

The city is a graybox made from engine primitive cubes, not a finished photorealistic environment. The player body is a capsule placeholder, and the sedan is built from primitive meshes. Vehicle movement is kinematic rather than Chaos suspension/traction physics. There are no NPCs, traffic simulation, missions, production character animations, production vehicle assets, authored World Partition district assets, or final art/audio yet.

## Build and test status

The repository has **not** been compiled with Unreal Build Tool in this session and has **not** been launched on an iPhone. GitHub Actions checks repository structure and Python syntax only; they do not compile Unreal C++.

The first map asset is generated locally by running the editor script described in [MAP_SETUP.md](MAP_SETUP.md). The iOS build still requires Unreal Engine with iOS support, Xcode, an Apple development team, and physical-device profiling.

## Next milestone

1. Generate the blockout map in Unreal Editor and compile the game/editor targets.
2. Fix any Unreal Header Tool, C++, or iOS SDK errors reported by the real toolchain.
3. Verify on iPhone 12 mini that movement, entering/exiting, steering, braking, and camera switching work.
4. Replace primitive character and vehicle meshes with original production assets.
5. Establish World Partition district cells and stream around the player and car.
