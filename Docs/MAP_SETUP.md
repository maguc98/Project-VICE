# Build and map setup

## Create the first map

The repository includes an Unreal Editor Python bootstrap script at:

`Content/Python/create_vice_blockout_map.py`

1. Open the project with Unreal Engine 5.4 on macOS or Windows.
2. Enable the bundled Python Script Plugin and Editor Scripting Utilities if Unreal asks to restart.
3. Open the Output Log.
4. Run:

```python
py "Content/Python/create_vice_blockout_map.py"
```

5. Save the project after the script reports that `/Game/Maps/L_ViceCity_Blockout` was created.

The script creates a map, sets the Project VICE game mode, places a PlayerStart, a directional sun linked to SkyAtmosphere, a SkyLight, SkyAtmosphere, and exponential height fog. The game mode spawns the runtime city streamer and the first sedan.
The iOS visitor-preview packaging script runs this bootstrap through UnrealEditor-Cmd before cooking. The editor startup map is set to the engine entry map so a clean checkout can open the editor before the generated project map exists; the packaged game still starts from the generated VICE blockout map.

## Current prototype behavior

- The city grid covers approximately 4.32 km × 4.32 km (25 × 25 road intersections, 24 × 24 blocks).
- The custom city streamer tracks the currently possessed pawn, so streaming follows the player on foot or while driving.
- A 5 × 5 neighborhood of cell actors is desired around the player; new cells are spawned nearest-first, up to 3 per 0.25-second update. Cells outside the radius are destroyed.
- Each cell creates ten instanced batches for dark asphalt, concrete sidewalks/curbs, building masses, dark glazing, road markings, facade trim, tree trunks/canopies, and a waterfront-only water surface. The water batch is empty outside the waterfront district.
- Roads receive dashed center markings and zebra crossings; each block receives a connected sidewalk loop, three deterministic building masses, repeated facade glazing, roof/belt trim, and eight low-poly sidewalk trees grouped into trunk/canopy batches.
- District identity is derived from cell coordinates: the central 5 × 5 cells are downtown, cells at Y ≤ -8 use a low-rise waterfront palette, the north-east edge at X ≥ 8 and Y ≥ 5 uses broader industrial masses, and remaining cells use the residential style. Re-streaming a cell reproduces its district and building variation.
- Waterfront cells reserve the outer block edge for a promenade, low seawall, and opaque water. The sea edge is split into three overlapping spans whose shoreline positions follow a deterministic low-frequency profile along the global X axis; the overlap avoids visible gaps and the same cell recreates the same contour after streaming. A sand-colored beach shelf fills the gap between seawall and water; each shelf segment is rotated into a gentle one-degree seaward slope. A narrow opaque sea-glass band overlays the near-shore water to distinguish shallow from deep water, reusing the existing glazing HISM and coastal tint; the white waterline accent stays at the surface. A compact park fills the inland strip with two planting beds, three stylized low-poly palms, two benches, and three lamp-post placeholders. Coastal cells skip generic trees that would overlap the sea edge.
- One simple sidewalk pedestrian patrol is spawned per active cell; this is capped by the 5 × 5 streaming window.
- A sparse deterministic pattern also spawns ambient road-loop cars; these are removed with their owning streamed cells.
- The player can walk, jump, sprint, and switch first-/third-person view. On touch devices, the left virtual stick drives movement or vehicle throttle/steering, the right virtual stick controls the camera, and the HUD buttons handle jump, sprint, brake, camera, and vehicle enter/exit.
- The first blockout sedan supports entering/exiting, throttle, reverse, steering, braking, camera switching, and a speed display.
- Mobile virtual joysticks drive movement/steering and camera look; the touch HUD provides jump, sprint, brake, camera, and enter/exit actions.

The cell actors are created and destroyed on the game thread. This is a bounded prototype streaming system, not yet Unreal World Partition or true asynchronous asset streaming. Fast movement may reveal cell pop-in or a frame-time spike and must be profiled on the iPhone 12 mini.

This is a color-separated low-poly graybox prototype, not final city art. The waterfront now has a procedural promenade, seawall, opaque blue water plane, and a small park made from reused HISM foliage/trim batches. Planting beds, palm crowns, benches, and lamp posts are still primitive graybox props; the lamps do not emit light. The shoreline is still a segmented primitive-mesh blockout with a simple sloped beach ramp, not a sculpted landscape. The shallow/deep transition is a static opaque color band, not a dynamic wave effect; there is no reflective/translucent water shader, wave simulation, or finished coastal asset. It currently uses engine primitive cubes and has no final character mesh, vehicle mesh, animation set, full NPC behavior, traffic-light/lane AI, missions, authored World Partition landscape, or final art/audio.

## Build validation

GitHub Actions validates repository structure, project JSON, and the Python bootstrap script. This is not an Unreal C++ compile. A real Unreal Editor/Build Toolchain and iOS SDK are required to compile and test on device.
