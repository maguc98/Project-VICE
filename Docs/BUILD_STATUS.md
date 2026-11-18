# Current build status

Last updated: 2026-11-19

## Implemented in source

- Unreal Engine 5.4 project descriptor, runtime module, and correctly named game/editor target files.
- Game mode bootstrap that creates the player start, streamed graybox city manager, and first vehicle.
- Custom city cell streaming for a 4.32 km × 4.32 km grid: 5 × 5 active cell window, nearest-first loading in batches of up to 3 chunks per 0.25-second update, and unloading outside the window.
- Deterministic per-cell city visuals split into nine HISM batches for asphalt, sidewalks/curbs, building masses, glazing, yellow lane lines, white crosswalks, facade trim, tree trunks, and tree canopies; streaming follows the active character or vehicle.
- Procedural road center lines, zebra crossings, connected block sidewalks, simple low-poly facade window/roof details, and eight instanced street trees per block.
- One lightweight sidewalk pedestrian patrol per active cell (up to 25), with distance-tiered tick intervals.
- Sparse ambient traffic cars following deterministic four-intersection road loops, with distance-tiered tick intervals and streamed cleanup.
- Character movement, jump, sprint, and first-/third-person camera toggle.
- Runtime mobile touch HUD with camera, jump, sprint, vehicle interaction, and brake buttons.
- Default virtual joystick axes mapped for movement, driving, and camera look.
- Arcade sedan prototype with throttle, reverse, steering, swept collision, camera toggle, enter/exit possession flow, and speed readout.
- Mobile day/night controller that animates the map Directional Light and Sky Light using a 20-minute in-game day.
- Unreal Editor Python script to create the initial map with player start and basic lighting actors.
- GitHub Actions repository structure and Python syntax checks.

## Current prototype limitations

The city is now a color-separated low-poly graybox made from engine primitive cubes, not a finished photorealistic environment. The current visual pass adds asphalt/concrete/building/glass material tints, road markings, zebra crossings, connected sidewalk loops, and simple facade details; original high-resolution art assets are still pending. The player body is a capsule placeholder, and the sedan is built from primitive meshes. Vehicle movement is kinematic rather than Chaos suspension/traction physics. The pedestrian system is currently a small capsule-placeholder patrol prototype only, and traffic is a sparse primitive-mesh road-loop prototype; there is no full NPC behavior/animation, traffic lights or lane AI, missions, production character animations, production vehicle assets, authored World Partition district assets, asynchronous asset streaming, or final art/audio yet. Cell actor creation/destruction currently runs on the game thread and may cause pop-in or hitches; no performance data has been collected.

## Build and test status

The repository has **not** been compiled with Unreal Build Tool in this session and has **not** been launched on an iPhone. GitHub Actions checks repository structure and Python syntax only; they do not compile Unreal C++.

The first map asset is generated locally by running the editor script described in [MAP_SETUP.md](MAP_SETUP.md). The iOS build still requires Unreal Engine with iOS support, Xcode, an Apple development team, and physical-device profiling.

## Next milestone

1. Generate the blockout map in Unreal Editor and compile the game/editor targets.
2. Fix any Unreal Header Tool, C++, or iOS SDK errors reported by the real toolchain.
3. Verify on iPhone 12 mini that movement, entering/exiting, steering, braking, and camera switching work.
4. Replace primitive character and vehicle meshes with original production assets.
5. Profile the custom cell streamer, then move to authored World Partition/HLOD and asynchronous asset streaming for production districts.
