# Technical design

## Product direction

Project VICE is an original fictional coastal metropolis. Its art direction aims for grounded, high-fidelity contemporary urban realism while remaining an independently designed game. Do not copy GTA maps, characters, logos, missions, UI, models, textures, audio, or other protected material.

## Runtime architecture

- **Game framework:** C++ gameplay foundation with Blueprint extension points.
- **Player:** CharacterMovement-based locomotion; camera boom supports third-/first-person modes.
- **Input:** Gameplay functions are callable from UMG touch controls. Enhanced Input can replace legacy bindings as the touch HUD is implemented.
- **World (prototype):** custom actor-cell streaming follows the currently possessed pawn, so it follows either the on-foot character or vehicle. A 5 × 5 active window is maintained in a deterministic 25 × 25 intersection grid. Current chunk actors group primitive road/building cube instances into one HISM component per cell and are spawned/destroyed in small game-thread batches.
- **World (production target):** evaluate Unreal World Partition / HLOD and asset streaming once the actual district art and authored map exist; do not call the current prototype true asynchronous asset streaming.
- **Vehicles:** current prototype uses swept arcade movement; evaluate Chaos Vehicles only after a lightweight mobile vehicle prototype is profiled.
- **Environment:** a one-second day/night controller updates the map Directional Light and Sky Light; sky capture is not forced each tick.
- **Simulation (prototype):** one capsule-placeholder sidewalk walker per active city cell; distant walkers tick less frequently. Traffic, crowd reactions, navmesh and skeletal animation remain future systems.
- **Persistence:** SaveGame snapshots for player, vehicles, mission state, and world changes.

## Visual strategy for iPhone 12 mini

- Use mobile forward rendering, Metal, mobile HDR, and a conservative 2x MSAA starting point; profile before raising sample count.
- Avoid desktop-only assumptions such as Lumen, hardware ray tracing, and Nanite as required runtime features.
- Bake static lighting where possible; reserve dynamic shadows for nearby/high-value actors.
- Use material complexity budgets, texture streaming, ASTC textures, mipmaps, and limited translucent layers.
- Use mesh LODs and HLODs, instancing, occlusion culling, and aggressive distance culling.
- Keep particle counts, real-time lights, reflection captures, and post-processing conservative.
- Use dynamic resolution and scalable quality presets; validate sustained performance under thermal load.

## World continuity

Outdoor traversal should avoid hard loading screens. Maintain a safety radius around the player/vehicle and overlap visible district silhouettes. Current cell actors are created in bounded game-thread batches, so profile cell transitions and visual pop-in; they are not asynchronous asset loads. Use skyline silhouettes and occlusion to maintain the sense of a continuous city. Interior spaces may be separate streamed levels or data layers; short transitions are acceptable when necessary.

## Camera

The initial C++ character has a basic spring-arm camera and a simple perspective toggle. Production first-person mode still needs eye-height calibration, body/weapon visibility rules (if applicable), camera collision, animation integration, and vehicle camera handoff.

## Security and licensing

Never commit signing certificates, provisioning profiles, API keys, private credentials, or proprietary third-party assets. Keep signing secrets in protected CI secrets only after the owner configures them.
