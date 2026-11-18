# Technical design

## Product direction

Project VICE is an original fictional coastal metropolis. Its art direction aims for grounded, high-fidelity contemporary urban realism while remaining an independently designed game. Do not copy GTA maps, characters, logos, missions, UI, models, textures, audio, or other protected material.

## Runtime architecture

- **Game framework:** C++ gameplay foundation with Blueprint extension points.
- **Player:** CharacterMovement-based locomotion; camera boom supports third-/first-person modes.
- **Input:** Gameplay functions are callable from UMG touch controls. Enhanced Input can replace legacy bindings as the touch HUD is implemented.
- **World:** World Partition with runtime grid streaming; streaming sources follow the player and active vehicle.
- **Vehicles:** Chaos Vehicles only after a lightweight mobile vehicle prototype is profiled.
- **Simulation:** NPC and traffic updates are distance/visibility tiered; distant agents use simplified representations.
- **Persistence:** SaveGame snapshots for player, vehicles, mission state, and world changes.

## Visual strategy for iPhone 12 mini

- Use mobile forward rendering and Metal.
- Avoid desktop-only assumptions such as Lumen, hardware ray tracing, and Nanite as required runtime features.
- Bake static lighting where possible; reserve dynamic shadows for nearby/high-value actors.
- Use material complexity budgets, texture streaming, ASTC textures, mipmaps, and limited translucent layers.
- Use mesh LODs and HLODs, instancing, occlusion culling, and aggressive distance culling.
- Keep particle counts, real-time lights, reflection captures, and post-processing conservative.
- Use dynamic resolution and scalable quality presets; validate sustained performance under thermal load.

## World continuity

Outdoor traversal should avoid hard loading screens. Stream cells asynchronously with a safety radius and overlap. Use skyline silhouettes and occlusion to maintain the sense of a continuous city. Interior spaces may be separate streamed levels or data layers; short transitions are acceptable when necessary.

## Camera

The initial C++ character has a basic spring-arm camera and a simple perspective toggle. Production first-person mode still needs eye-height calibration, body/weapon visibility rules (if applicable), camera collision, animation integration, and vehicle camera handoff.

## Security and licensing

Never commit signing certificates, provisioning profiles, API keys, private credentials, or proprietary third-party assets. Keep signing secrets in protected CI secrets only after the owner configures them.
