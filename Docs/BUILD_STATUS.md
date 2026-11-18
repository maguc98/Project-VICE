# Current build status

Last updated: 2026-11-18

## Repository bootstrap

- Unreal project descriptor: committed.
- C++ runtime module: committed.
- Basic character movement and camera perspective toggle: committed.
- Game mode: committed.
- Initial mobile/iOS configuration: committed.
- Default Unreal virtual joystick: configured as a temporary touch-control baseline.
- Repository structure validation workflow: committed.

## Not yet built or verified

No Unreal Editor/Build Toolchain was run in this session. Therefore this repository has **not** yet been proven to compile, launch, or run on an iPhone. The iOS project still needs editor-generated assets/maps, a proper touch HUD, production character/vehicle/environment assets, World Partition setup, device profiling, and Apple signing.

The default virtual joystick is only a temporary input baseline; it is not the planned polished on-screen HUD.

## Next engineering tasks

1. Open and compile with the project's selected Unreal Engine version on macOS.
2. Fix any UHT/C++ or iOS SDK issues found by the real toolchain.
3. Create the first playable test map and configure it as the startup map.
4. Replace the default joystick with a purpose-built touch HUD.
5. Add a first drivable vehicle and a streamed test district.
6. Profile on the actual iPhone 12 mini before increasing visual complexity.
