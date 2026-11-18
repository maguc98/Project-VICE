import unreal

MAP_PATH = "/Game/Maps/L_ViceCity_Blockout"


def build_vice_city_blockout():
    """Create and save the first playable map shell in Unreal Editor."""
    if not unreal.EditorLevelLibrary.new_level(MAP_PATH):
        raise RuntimeError("Could not create map: " + MAP_PATH)

    world = unreal.EditorLevelLibrary.get_editor_world()
    if not world:
        raise RuntimeError("Editor world is unavailable")

    game_mode = unreal.load_class(None, "/Script/ProjectVICE.VICEGameMode")
    if game_mode:
        world.get_world_settings().set_editor_property("default_game_mode", game_mode)

    unreal.EditorLevelLibrary.spawn_actor_from_class(
        unreal.PlayerStart,
        unreal.Vector(0.0, 0.0, 120.0),
        unreal.Rotator(0.0, 0.0, 0.0),
    )

    sun = unreal.EditorLevelLibrary.spawn_actor_from_class(
        unreal.DirectionalLight,
        unreal.Vector(0.0, 0.0, 12000.0),
        unreal.Rotator(-42.0, -32.0, 0.0),
    )
    if sun:
        sun.set_actor_label("VICE_Sun_Directional")

    sky = unreal.EditorLevelLibrary.spawn_actor_from_class(
        unreal.SkyLight,
        unreal.Vector(0.0, 0.0, 8000.0),
        unreal.Rotator(0.0, 0.0, 0.0),
    )
    if sky:
        sky.set_actor_label("VICE_SkyLight")

    fog = unreal.EditorLevelLibrary.spawn_actor_from_class(
        unreal.ExponentialHeightFog,
        unreal.Vector(0.0, 0.0, 0.0),
        unreal.Rotator(0.0, 0.0, 0.0),
    )
    if fog:
        fog.set_actor_label("VICE_AtmosphericFog")

    if not unreal.EditorLevelLibrary.save_current_level():
        raise RuntimeError("Could not save map: " + MAP_PATH)

    unreal.log("Project VICE blockout map created: " + MAP_PATH)


build_vice_city_blockout()
