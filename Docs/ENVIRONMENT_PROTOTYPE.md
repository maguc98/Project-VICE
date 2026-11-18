# Environment prototype

## Day/night cycle

`AVICEDayNightController` looks for the map's first Directional Light and Sky Light during startup. It advances a 24-hour clock and updates the sun rotation, sun intensity, sun tint, and sky ambient intensity/color once per second.

Defaults:
- Starting time: 14:00.
- Full in-game day: 1,200 real-time seconds (20 minutes).
- Sun intensity cap: 8.0 using the map light's current intensity units.
- Time can be changed at runtime with `SetTimeOfDay(float Hours)`.

The map bootstrap script creates the required Directional Light and Sky Light. The cycle is a basic directional-light approximation: it does not yet model latitude, seasons, clouds, moon phases, stars, or physically correct atmospheric scattering. SkyLight recapture is intentionally not forced each update to avoid expensive runtime captures on iPhone 12 mini.

## Mobile considerations

The cycle updates at a one-second actor tick rather than every frame. Profile dynamic shadows, light intensity, and tone mapping on device before enabling additional moving lights or expensive sky effects.
