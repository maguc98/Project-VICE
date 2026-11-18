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

The script creates a map, sets the Project VICE game mode, places a PlayerStart, directional sun, skylight, and exponential height fog. The game mode then creates the procedural graybox street grid at runtime.

## Current prototype behavior

- A 7-by-7 street grid is generated around the player spawn.
- Three primitive building masses are generated in each city block.
- The player can walk, jump, sprint (keyboard/controller binding), and toggle camera perspective.
- Default Unreal mobile virtual joysticks are configured as a temporary movement/look input source.

This is a graybox prototype, not final city art. It currently uses engine primitive cubes and has no final character mesh, animations, vehicle, NPCs, missions, custom touch buttons, or World Partition district assets.

## Build validation

GitHub Actions validates repository structure, project JSON, and the Python bootstrap script. This is not an Unreal C++ compile. A real Unreal Editor/Build Toolchain and iOS SDK are required to compile and test on device.
