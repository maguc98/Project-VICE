#!/usr/bin/env python3
"""Check source-level city invariants. This does not compile Unreal C++."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Source" / "ProjectVICE"


def read(relative_path: str) -> str:
    path = SOURCE / relative_path
    if not path.is_file():
        raise SystemExit(f"Missing source file: {path.relative_to(ROOT)}")
    return path.read_text(encoding="utf-8")


header = read("VICECityChunk.h")
chunk = read("VICECityChunk.cpp")
generator = read("VICECityGenerator.cpp")
pedestrian = read("VICEPedestrian.cpp")

batches = (
    "RoadInstances",
    "SidewalkInstances",
    "BuildingInstances",
    "GlassInstances",
    "LaneLineInstances",
    "CrosswalkInstances",
    "TrimInstances",
    "TreeTrunkInstances",
    "TreeCanopyInstances",
    "WaterInstances",
)

for batch in batches:
    declaration = f"TObjectPtr<UHierarchicalInstancedStaticMeshComponent> {batch};"
    construction = f'CreateDefaultSubobject<UHierarchicalInstancedStaticMeshComponent>(TEXT("{batch}"))'
    if declaration not in header:
        raise SystemExit(f"Missing HISM declaration: {batch}")
    if construction not in chunk:
        raise SystemExit(f"Missing HISM construction: {batch}")

if "SceneRoot->SetMobility(EComponentMobility::Static);" not in chunk:
    raise SystemExit("City chunk root must use static mobility.")
if chunk.count("SetMobility(EComponentMobility::Static);") != len(batches) + 1:
    raise SystemExit("Every city HISM batch and its root must use static mobility.")

signature = "void InitializeMaterials(const FIntPoint& Coordinates);"
if signature not in header or "void AVICECityChunk::InitializeMaterials(const FIntPoint& Coordinates)" not in chunk:
    raise SystemExit("District-aware material declaration/definition mismatch.")
if "InitializeMaterials(Coordinates);" not in chunk:
    raise SystemExit("Cell coordinates are not passed into material initialization.")

district_rules = (
    "const bool bDowntown = FMath::Abs(Coordinates.X) <= 2 && FMath::Abs(Coordinates.Y) <= 2;",
    "const bool bWaterfront = !bDowntown && Coordinates.Y <= -8;",
    "const bool bIndustrial = !bDowntown && !bWaterfront && Coordinates.X >= 8 && Coordinates.Y >= 5;",
)
for rule in district_rules:
    if chunk.count(rule) != 2:
        raise SystemExit(f"District material/building rules must match in both locations: {rule}")

if "const float WidthBase = bIndustrial ? 5000.0f" not in chunk:
    raise SystemExit("Industrial building width guard is missing.")
if "const float WidthRange = bIndustrial ? 1200.0f" not in chunk:
    raise SystemExit("Industrial building width range is missing.")

# Waterfront-only geometry must use a dedicated, non-colliding HISM batch.
if "WaterMaterial = bWaterfront ?" not in chunk:
    raise SystemExit("Water material must only be allocated for waterfront cells.")
if "WaterInstances->SetCollisionEnabled(ECollisionEnabled::NoCollision);" not in chunk:
    raise SystemExit("Water placeholder must not block player movement.")
if "AddCube(WaterInstances, FVector(HalfCell, CellSpacing * 0.805f" not in chunk:
    raise SystemExit("Water surface placement is missing.")
if "FVector(HalfCell, CellSpacing * 0.63f, 9.0f)" not in chunk:
    raise SystemExit("Waterfront promenade placement is missing.")
if "const float WaterfrontY[] = { 0.22f, 0.22f, 0.38f };" not in chunk:
    raise SystemExit("Waterfront buildings are not shifted inland to make room for the park.")

# Coastal park details reuse existing HISM batches; no new component batch is allowed.
park_invariants = (
    "if (bWaterfront && TreeLocation.Y > 6000.0f)",
    "const FVector CoastalPalmLocations[]",
    "const FVector BenchLocations[]",
    "const FVector ParkLightLocations[]",
    "FVector(CellSpacing * 0.28f, CellSpacing * 0.535f, 65.0f)",
    "FVector(CellSpacing * 0.72f, CellSpacing * 0.535f, 65.0f)",
    "AddCube(TrimInstances, BenchLocation + FVector(0.0f, 0.0f, 125.0f)",
    "AddCube(TrimInstances, LightLocation + FVector(0.0f, 0.0f, 1500.0f)",
)
for invariant in park_invariants:
    if invariant not in chunk:
        raise SystemExit(f"Missing waterfront park invariant: {invariant}")

# The pedestrian spawn and its patrol loop must remain on the sidewalk centerline.
if "const float SidewalkInset = 1300.0f;" not in pedestrian:
    raise SystemExit("Pedestrian sidewalk inset changed unexpectedly.")
if "const float Height = 110.0f;" not in pedestrian:
    raise SystemExit("Pedestrian sidewalk height changed unexpectedly.")
if "FVector(1300.0f, 1300.0f, 110.0f)" not in generator:
    raise SystemExit("Initial pedestrian spawn no longer matches its patrol route.")

print(
    "City source invariants passed: "
    f"{len(batches)} HISM batches, deterministic district rules, "
    "static component mobility, waterfront water/promenade/park props, and sidewalk patrol alignment. "
    "This is not an Unreal C++ compile."
)
