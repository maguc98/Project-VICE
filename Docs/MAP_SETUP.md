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

The script creates a map, sets the Project VICE game mode, places a PlayerStart, directional sun, skylight, and exponential height fog. The game mode spawns the runtime city streamer and the first sedan.

## Current prototype behavior

- The city grid covers approximately 4.32 km × 4.32 km (25 × 25 road intersections, 24 × 24 blocks).
- The custom city streamer tracks the currently possessed pawn, so streaming follows the player on foot or while driving.
- A 5 × 5 neighborhood of cell actors is desired around the player; new cells are spawned nearest-first, up to 3 per 0.25-second update. Cells outside the radius are destroyed.
- Each cell creates separate instanced batches for dark asphalt, concrete sidewalks/curbs, building masses, dark glazing, road markings, and facade trim.
- Roads receive dashed center markings and zebra crossings; each block receives a connected sidewalk loop, three deterministic building masses, repeated facade glazing, roof/belt trim, and eight low-poly sidewalk trees grouped into trunk/canopy batches.
- One simple sidewalk pedestrian patrol is spawned per active cell; this is capped by the 5 × 5 streaming window.
- A sparse deterministic pattern also spawns ambient road-loop cars; these are removed with their owning streamed cells.
- The player can walk, jump, sprint, and switch first-/third-person view.
- The first blockout sedan supports entering/exiting, throttle, reverse, steering, braking, camera switching, and a speed display.
- Mobile virtual joysticks drive movement/steering and camera look; the touch HUD provides jump, sprint, brake, camera, and enter/exit actions.

The cell actors are created and destroyed on the game thread. This is a bounded prototype streaming system, not yet Unreal World Partition or true asynchronous asset streaming. Fast movement may reveal cell pop-in or a frame-time spike and must be profiled on the iPhone 12 mini.

This is a color-separated low-poly graybox prototype, not final city art. It currently uses engine primitive cubes and has no final character mesh, vehicle mesh, animation set, full NPC behavior, traffic-light/lane AI, missions, authored World Partition landscape, or final art/audio.

## Build validation

GitHub Actions validates repository structure, project JSON, and the Python bootstrap script. This is not an Unreal C++ compile. A real Unreal Editor/Build Toolchain and iOS SDK are required to compile and test on device.
