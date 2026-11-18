# City visual style and asset brief

## Visual identity

Project VICE is an original contemporary coastal metropolis. The visual direction is sun-washed, grounded, and modern: dark asphalt, pale concrete, warm neutral building facades, cool blue-green glazing, restrained yellow road paint, and deep coastal vegetation. Avoid copying any recognizable real-world game map, branded architecture, or proprietary art.

## Current runtime graybox palette

| Surface | Starting color | Material intent |
|---|---|---|
| Asphalt | Near-black charcoal | High roughness, low visual noise |
| Sidewalk / curb | Mid concrete gray | Matte concrete |
| Building mass | Warm limestone / sand | Matte plaster and concrete |
| Windows | Deep blue-green | Dark reflective glazing placeholder |
| Lane center lines | Warm traffic yellow | Slightly rough road paint |
| Crosswalks | Warm off-white | Flat road marking |
| Facade trim | Pale warm gray | Concrete/parapet accent |
| Tree trunks | Dark warm brown | Bark placeholder |
| Tree canopies | Muted coastal green | Foliage placeholder |

The current implementation uses nine HISM material batches per streamed cell. The palette is a blockout guide, not a final PBR material library.

## District identity targets

- **Downtown core:** taller mixed-use towers, denser street walls, smaller sidewalks and more street furniture.
- **Residential neighborhoods:** lower-rise apartments, detached homes, planted setbacks, quieter streets.
- **Waterfront:** low-rise commercial buildings, open sightlines, palms and coastal planting, promenade spaces.
- **Industrial edge:** warehouses, service yards, loading bays, utility structures and wider roads.

## Production asset pipeline

1. Model original modular building kits in Blender or an equivalent DCC.
2. Keep pivots at ground level and dimensions in centimeters on export.
3. Author mobile-friendly PBR materials with packed ORM textures where appropriate.
4. Create at least three LODs for prominent buildings and aggressive simplified distant silhouettes.
5. Use 1K–2K ASTC-compressed textures for hero assets only where profiling justifies them; background kits should use smaller shared atlases.
6. Import as reusable Static Mesh assets and replace the primitive cube instances by district/asset category.
7. Profile HISM/ISM choice, culling distance, collision complexity, draw calls, memory and thermal behavior on the iPhone 12 mini.

## Current limitations

The current buildings, glazing, trees, road markings and sidewalks are procedural primitive-mesh assemblies. They do not yet contain authored UVs, texture atlases, physically based facade materials, real tree meshes, unique silhouettes, signs, street furniture, or baked lighting. Do not describe this stage as photorealistic until those assets exist and are validated in the running game.
