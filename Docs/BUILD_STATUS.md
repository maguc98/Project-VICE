# Current build status

Last updated: 2026-11-19

## Implemented in source

- Unreal Engine 5.4 project descriptor, runtime module, and correctly named game/editor target files.
- Game mode bootstrap that creates the player start, streamed graybox city manager, and first vehicle.
- Custom city cell streaming for a 4.32 km × 4.32 km grid: 5 × 5 active cell window, nearest-first loading in batches of up to 3 chunks per 0.25-second update, and unloading outside the window.
- Deterministic per-cell city visuals split into ten HISM batches for asphalt, sidewalks/curbs, building masses, glazing, yellow lane lines, white crosswalks, facade trim, tree trunks/canopies, and waterfront-only water; the chunk root and visual batches use static mobility.
- Procedural road center lines, zebra crossings, connected block sidewalks, simple low-poly facade window/roof details, and eight instanced street trees per block.
- Waterfront-only promenade and low seawall, plus a deterministic stepped bay edge made from three overlapping opaque water spans. A sand-colored shoreline shelf uses a one-degree rotated primitive ramp for a gentle seaward fall. A narrow opaque sea-glass band distinguishes shallow from deep water using the existing glazing HISM and coastal tint; a thin off-white waterline accent stays at the surface. The shallow band is static, not animated. The inland park adds two planting beds, three stylized palms, two benches, and three lamp-post placeholders; generic outer-edge trees are omitted in coastal cells to avoid overlap.
- Coordinate-derived district variation: downtown towers, lower-rise southern waterfront blocks, broader industrial buildings in the north-east, and residential fabric elsewhere; district palettes vary without adding HISM component batches.
- One lightweight sidewalk pedestrian patrol per active cell (up to 25), with distance-tiered tick intervals.
- Sparse ambient traffic cars following deterministic four-intersection road loops, with distance-tiered tick intervals and streamed cleanup.
- Character movement, jump, sprint, and first-/third-person camera toggle.
- Runtime mobile touch HUD with camera, jump, sprint, vehicle interaction, and brake buttons.
- Default virtual joystick axes mapped for movement, driving, and camera look.
- Arcade sedan prototype with throttle, reverse, steering, swept collision, camera toggle, enter/exit possession flow, and speed readout.
- Mobile day/night controller that animates the map Directional Light and Sky Light using a 20-minute in-game day.
- Unreal Editor Python script to create the initial map with player start and basic lighting actors.
- Direct-to-game guest preview flow with a visible `PROJECT VICE / 游客预览版` HUD label, touch-control hints, and an on-foot/vehicle status readout; no account flow is required.
- iOS visitor-preview packaging scaffolding: command-line map generation, local signing checks, Unreal Automation Tool BuildCookRun script, and a manual self-hosted macOS GitHub Actions workflow with IPA artifact upload. Signing assets stay on the build machine.
- GitHub Actions repository structure, project JSON, Python syntax, and city source-level invariant checks (not an Unreal C++ compile).

## Current prototype limitations

The city is now a color-separated low-poly graybox made from engine primitive meshes, not a finished photorealistic environment. District variation changes building mass proportions and material palette. The waterfront includes a promenade, seawall, opaque water plane, and primitive park dressing (planting beds, stylized palms, benches, and non-emissive lamp-post placeholders), but the shoreline is still a procedural primitive-mesh blockout with a basic one-degree sloped beach ramp rather than a sculpted beach; there is no functional park lighting, reflective/translucent water material, or dynamic wave simulation. The current visual pass adds asphalt/concrete/building/glass material tints, road markings, zebra crossings, connected sidewalk loops, and simple facade details; original high-resolution art assets are still pending. The player body is a capsule placeholder, and the sedan is built from primitive meshes. Vehicle movement is kinematic rather than Chaos suspension/traction physics. The pedestrian system is currently a small capsule-placeholder patrol prototype only, and traffic is a sparse primitive-mesh road-loop prototype; there is no full NPC behavior/animation, traffic lights or lane AI, missions, production character animations, production vehicle assets, authored World Partition district assets, asynchronous asset streaming, or final art/audio yet. Cell actor creation/destruction currently runs on the game thread and may cause pop-in or hitches; no performance data has been collected.

## Build and test status

The repository has **not** been compiled with Unreal Build Tool in this session and has **not** been launched on an iPhone. The standard GitHub Actions workflow validates source/configuration and packaging-script wiring only; it does not compile Unreal C++. The signed iOS workflow requires a configured self-hosted macOS runner with Unreal Engine 5.4, Xcode, and a matching local Apple signing identity/provisioning profile. No IPA has been produced in this session.

The first map asset is generated locally by running the editor script described in [MAP_SETUP.md](MAP_SETUP.md). The iOS build still requires Unreal Engine with iOS support, Xcode, an Apple development team, and physical-device profiling.

## Next milestone

1. Generate the blockout map in Unreal Editor and compile the game/editor targets.
2. Fix any Unreal Header Tool, C++, or iOS SDK errors reported by the real toolchain.
3. Verify on iPhone 12 mini that movement, entering/exiting, steering, braking, and camera switching work.
4. Replace primitive character and vehicle meshes with original production assets.
5. Profile the custom cell streamer, then move to authored World Partition/HLOD and asynchronous asset streaming for production districts.
