# Traffic prototype

## Current implementation

The custom city streamer creates a sparse set of ambient traffic cars. A deterministic cell pattern spawns a traffic actor in selected active cells, keeping the population low and repeatable when streaming in/out.

Each traffic car:
- Uses an engine-cube graybox sedan body and a blocking box collision volume.
- Follows a four-corner loop through the cross-street grid.
- Uses swept movement and turns at intersections.
- Slows/holds when blocked, then advances to its next route point if the obstruction persists.
- Updates less frequently when far from the player.

The traffic car is an ambient actor, not a player vehicle. The player-controlled sedan remains a separate pawn with enter/exit and touch-driving controls.

## Known limitations

This is a road-loop movement prototype, not full traffic AI. There are no traffic lights, lane changes, following distances, intersection priority, parking, route planning, vehicle damage, horns, audio, or skeletal vehicle assets. Multiple cars can still meet at intersections or block one another. Route and collision behavior must be tested in Unreal and profiled on iPhone 12 mini before increasing density.
