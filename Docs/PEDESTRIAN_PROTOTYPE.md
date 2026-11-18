# Pedestrian prototype

## Current implementation

The graybox city streamer spawns one lightweight pedestrian actor for each active city cell and destroys it when that cell leaves the streaming window.

Each pedestrian:
- Uses a capsule collision body and an engine capsule mesh placeholder.
- Patrols a deterministic four-corner loop aligned to the sidewalk centerlines inside its cell.
- Uses swept movement and turns toward the next waypoint.
- Skips a waypoint if a blocking collision interrupts the path.
- Is spawned with a per-cell route seed so neighboring walkers do not all start at the same corner/direction.

With the current 5 × 5 streaming window, the active pedestrian population is capped at 25 actors.

## Known limitations

This is a movement/streaming proof of concept, not a finished pedestrian simulation. It does not yet include skeletal human models, animation blueprints, navmesh pathfinding, crossing signals, crowd reactions, dialogue, schedules, avoidance steering, or police behavior. The current capsule placeholder and route paths must be replaced with authored sidewalk paths and original character assets.

The patrol loop is bounded to one cell and follows a simple rectangle. Collision may cause a walker to skip a waypoint. Test near building corners and while driving before expanding the active population.
