# Baseline device budgets

Target device: iPhone 12 mini (A14). These are starting engineering budgets, not measured results. They must be validated on physical hardware and adjusted using Unreal Insights, Xcode Instruments, and on-device frame-time captures.

| Area | Initial target / rule |
|---|---|
| Frame rate | 30 FPS sustained baseline |
| Frame time | 33.3 ms total frame budget |
| Memory | Keep a conservative resident asset budget; avoid loading multiple districts at full detail |
| Rendering | Mobile forward, Metal, dynamic resolution |
| Geometry | LOD/HLOD and instancing; ten material-batched HISM components per graybox cell (water batch populated only in waterfront cells); park foliage, furniture, the rotated beach ramp, and the shallow-water band reuse existing batches instead of adding components; no Nanite dependency |
| Lighting | Mostly baked/static; current city graybox lets building masses cast shadows while disabling shadows on small decorative batches |
| Textures | ASTC, mipmaps, streaming, platform-specific max sizes |
| Effects | Low overdraw; cap particles and translucency; keep the prototype water surface opaque to avoid large translucent overdraw; its segmented shoreline reuses existing HISM batches |
| Streaming | Target: 25 active city chunks, up to 25 placeholder pedestrians, and sparse traffic actors; at most 3 chunks spawned per 0.25-second update in the current prototype |
| Thermal | Profile sustained sessions, not only short benchmark runs |

## Quality tiers

- **Performance:** lower internal resolution, shorter view distance, simplified shadows/effects.
- **Balanced:** default target for iPhone 12 mini.
- **Quality:** higher resolution and view distance only when thermals and frame time permit.

Never claim a frame-rate or memory target is achieved until it has been measured on device.
