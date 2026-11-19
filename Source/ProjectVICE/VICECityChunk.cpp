#include "VICECityChunk.h"
#include "Components/SceneComponent.h"
#include "Components/HierarchicalInstancedStaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "Materials/MaterialInterface.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "UObject/ConstructorHelpers.h"

namespace VICECityVisuals
{
    static UMaterialInstanceDynamic* MakeColorMaterial(UMaterialInterface* Parent, UObject* Outer, const FLinearColor& Color, float Roughness)
    {
        if (!Parent || !Outer)
        {
            return nullptr;
        }

        UMaterialInstanceDynamic* Material = UMaterialInstanceDynamic::Create(Parent, Outer);
        if (Material)
        {
            Material->SetVectorParameterValue(TEXT("Color"), Color);
            Material->SetScalarParameterValue(TEXT("Roughness"), Roughness);
        }
        return Material;
    }
}

AVICECityChunk::AVICECityChunk()
{
    PrimaryActorTick.bCanEverTick = false;

    SceneRoot = CreateDefaultSubobject<USceneComponent>(TEXT("SceneRoot"));
    SceneRoot->SetMobility(EComponentMobility::Static);
    RootComponent = SceneRoot;

    RoadInstances = CreateDefaultSubobject<UHierarchicalInstancedStaticMeshComponent>(TEXT("RoadInstances"));
    RoadInstances->SetupAttachment(SceneRoot);
    RoadInstances->SetMobility(EComponentMobility::Static);
    RoadInstances->SetCollisionProfileName(TEXT("BlockAll"));
    RoadInstances->SetCastShadow(false);

    SidewalkInstances = CreateDefaultSubobject<UHierarchicalInstancedStaticMeshComponent>(TEXT("SidewalkInstances"));
    SidewalkInstances->SetupAttachment(SceneRoot);
    SidewalkInstances->SetMobility(EComponentMobility::Static);
    SidewalkInstances->SetCollisionProfileName(TEXT("BlockAll"));
    SidewalkInstances->SetCastShadow(false);

    BuildingInstances = CreateDefaultSubobject<UHierarchicalInstancedStaticMeshComponent>(TEXT("BuildingInstances"));
    BuildingInstances->SetupAttachment(SceneRoot);
    BuildingInstances->SetMobility(EComponentMobility::Static);
    BuildingInstances->SetCollisionProfileName(TEXT("BlockAll"));
    BuildingInstances->SetCastShadow(true);

    GlassInstances = CreateDefaultSubobject<UHierarchicalInstancedStaticMeshComponent>(TEXT("GlassInstances"));
    GlassInstances->SetupAttachment(SceneRoot);
    GlassInstances->SetMobility(EComponentMobility::Static);
    GlassInstances->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    GlassInstances->SetCastShadow(false);

    LaneLineInstances = CreateDefaultSubobject<UHierarchicalInstancedStaticMeshComponent>(TEXT("LaneLineInstances"));
    LaneLineInstances->SetupAttachment(SceneRoot);
    LaneLineInstances->SetMobility(EComponentMobility::Static);
    LaneLineInstances->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    LaneLineInstances->SetCastShadow(false);

    CrosswalkInstances = CreateDefaultSubobject<UHierarchicalInstancedStaticMeshComponent>(TEXT("CrosswalkInstances"));
    CrosswalkInstances->SetupAttachment(SceneRoot);
    CrosswalkInstances->SetMobility(EComponentMobility::Static);
    CrosswalkInstances->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    CrosswalkInstances->SetCastShadow(false);

    TrimInstances = CreateDefaultSubobject<UHierarchicalInstancedStaticMeshComponent>(TEXT("TrimInstances"));
    TrimInstances->SetupAttachment(SceneRoot);
    TrimInstances->SetMobility(EComponentMobility::Static);
    TrimInstances->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    TrimInstances->SetCastShadow(false);

    TreeTrunkInstances = CreateDefaultSubobject<UHierarchicalInstancedStaticMeshComponent>(TEXT("TreeTrunkInstances"));
    TreeTrunkInstances->SetupAttachment(SceneRoot);
    TreeTrunkInstances->SetMobility(EComponentMobility::Static);
    TreeTrunkInstances->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    TreeTrunkInstances->SetCastShadow(false);

    TreeCanopyInstances = CreateDefaultSubobject<UHierarchicalInstancedStaticMeshComponent>(TEXT("TreeCanopyInstances"));
    TreeCanopyInstances->SetupAttachment(SceneRoot);
    TreeCanopyInstances->SetMobility(EComponentMobility::Static);
    TreeCanopyInstances->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    TreeCanopyInstances->SetCastShadow(false);

    WaterInstances = CreateDefaultSubobject<UHierarchicalInstancedStaticMeshComponent>(TEXT("WaterInstances"));
    WaterInstances->SetupAttachment(SceneRoot);
    WaterInstances->SetMobility(EComponentMobility::Static);
    WaterInstances->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    WaterInstances->SetCastShadow(false);

    static ConstructorHelpers::FObjectFinder<UStaticMesh> CubeAsset(TEXT("/Engine/BasicShapes/Cube.Cube"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> CylinderAsset(TEXT("/Engine/BasicShapes/Cylinder.Cylinder"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> SphereAsset(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    static ConstructorHelpers::FObjectFinder<UMaterialInterface> BasicMaterial(TEXT("/Engine/BasicShapes/BasicShapeMaterial.BasicShapeMaterial"));

    if (CubeAsset.Succeeded())
    {
        CubeMesh = CubeAsset.Object;
        RoadInstances->SetStaticMesh(CubeMesh);
        SidewalkInstances->SetStaticMesh(CubeMesh);
        BuildingInstances->SetStaticMesh(CubeMesh);
        GlassInstances->SetStaticMesh(CubeMesh);
        LaneLineInstances->SetStaticMesh(CubeMesh);
        CrosswalkInstances->SetStaticMesh(CubeMesh);
        TrimInstances->SetStaticMesh(CubeMesh);
        WaterInstances->SetStaticMesh(CubeMesh);
    }

    if (CylinderAsset.Succeeded())
    {
        CylinderMesh = CylinderAsset.Object;
        TreeTrunkInstances->SetStaticMesh(CylinderMesh);
    }

    if (SphereAsset.Succeeded())
    {
        SphereMesh = SphereAsset.Object;
        TreeCanopyInstances->SetStaticMesh(SphereMesh);
    }

    if (BasicMaterial.Succeeded())
    {
        BaseColorMaterial = BasicMaterial.Object;
    }
}

void AVICECityChunk::InitializeMaterials(const FIntPoint& Coordinates)
{
    if (!BaseColorMaterial)
    {
        return;
    }

    const bool bDowntown = FMath::Abs(Coordinates.X) <= 2 && FMath::Abs(Coordinates.Y) <= 2;
    const bool bWaterfront = !bDowntown && Coordinates.Y <= -8;
    const bool bIndustrial = !bDowntown && !bWaterfront && Coordinates.X >= 8 && Coordinates.Y >= 5;

    const FLinearColor SidewalkColor = bWaterfront
        ? FLinearColor(0.43f, 0.41f, 0.36f, 1.0f)
        : (bIndustrial ? FLinearColor(0.29f, 0.31f, 0.32f, 1.0f) : FLinearColor(0.34f, 0.36f, 0.37f, 1.0f));
    const FLinearColor BuildingColor = bWaterfront
        ? FLinearColor(0.72f, 0.68f, 0.57f, 1.0f)
        : (bIndustrial ? FLinearColor(0.43f, 0.45f, 0.43f, 1.0f) : FLinearColor(0.62f, 0.59f, 0.52f, 1.0f));
    const FLinearColor GlassColor = bWaterfront
        ? FLinearColor(0.08f, 0.19f, 0.22f, 1.0f)
        : (bIndustrial ? FLinearColor(0.10f, 0.13f, 0.14f, 1.0f) : FLinearColor(0.055f, 0.12f, 0.17f, 1.0f));
    const FLinearColor CanopyColor = bWaterfront
        ? FLinearColor(0.16f, 0.34f, 0.25f, 1.0f)
        : FLinearColor(0.12f, 0.28f, 0.16f, 1.0f);

    RoadMaterial = VICECityVisuals::MakeColorMaterial(BaseColorMaterial, this, FLinearColor(0.035f, 0.045f, 0.055f, 1.0f), 0.92f);
    SidewalkMaterial = VICECityVisuals::MakeColorMaterial(BaseColorMaterial, this, SidewalkColor, 0.86f);
    BuildingMaterial = VICECityVisuals::MakeColorMaterial(BaseColorMaterial, this, BuildingColor, 0.82f);
    GlassMaterial = VICECityVisuals::MakeColorMaterial(BaseColorMaterial, this, GlassColor, 0.24f);
    LaneLineMaterial = VICECityVisuals::MakeColorMaterial(BaseColorMaterial, this, FLinearColor(0.96f, 0.72f, 0.18f, 1.0f), 0.72f);
    CrosswalkMaterial = VICECityVisuals::MakeColorMaterial(BaseColorMaterial, this, FLinearColor(0.92f, 0.93f, 0.88f, 1.0f), 0.78f);
    TrimMaterial = VICECityVisuals::MakeColorMaterial(BaseColorMaterial, this, FLinearColor(0.78f, 0.76f, 0.69f, 1.0f), 0.82f);
    TreeTrunkMaterial = VICECityVisuals::MakeColorMaterial(BaseColorMaterial, this, FLinearColor(0.22f, 0.14f, 0.09f, 1.0f), 0.94f);
    TreeCanopyMaterial = VICECityVisuals::MakeColorMaterial(BaseColorMaterial, this, CanopyColor, 0.9f);
    WaterMaterial = bWaterfront ? VICECityVisuals::MakeColorMaterial(BaseColorMaterial, this, FLinearColor(0.035f, 0.22f, 0.30f, 1.0f), 0.28f) : nullptr;

    RoadInstances->SetMaterial(0, RoadMaterial);
    SidewalkInstances->SetMaterial(0, SidewalkMaterial);
    BuildingInstances->SetMaterial(0, BuildingMaterial);
    GlassInstances->SetMaterial(0, GlassMaterial);
    LaneLineInstances->SetMaterial(0, LaneLineMaterial);
    CrosswalkInstances->SetMaterial(0, CrosswalkMaterial);
    TrimInstances->SetMaterial(0, TrimMaterial);
    TreeTrunkInstances->SetMaterial(0, TreeTrunkMaterial);
    TreeCanopyInstances->SetMaterial(0, TreeCanopyMaterial);
    if (WaterMaterial)
    {
        WaterInstances->SetMaterial(0, WaterMaterial);
    }
}

void AVICECityChunk::AddMeshInstance(
    UHierarchicalInstancedStaticMeshComponent* Target,
    UStaticMesh* Mesh,
    const FVector& LocalLocation,
    const FVector& Dimensions)
{
    if (!Target || !Mesh)
    {
        return;
    }

    const FTransform InstanceTransform(
        FRotator::ZeroRotator,
        LocalLocation,
        Dimensions / 100.0f);

    Target->AddInstance(InstanceTransform);
}

void AVICECityChunk::AddCube(
    UHierarchicalInstancedStaticMeshComponent* Target,
    const FVector& LocalLocation,
    const FVector& Dimensions)
{
    AddMeshInstance(Target, CubeMesh, LocalLocation, Dimensions);
}

void AVICECityChunk::InitializeCell(const FIntPoint& Coordinates, float CellSpacing, float RoadWidth)
{
    if (bInitialized || !RoadInstances || !SidewalkInstances || !BuildingInstances || !LaneLineInstances || !CrosswalkInstances || !WaterInstances || !CubeMesh)
    {
        return;
    }
    bInitialized = true;
    InitializeMaterials(Coordinates);

    const bool bDowntown = FMath::Abs(Coordinates.X) <= 2 && FMath::Abs(Coordinates.Y) <= 2;
    const bool bWaterfront = !bDowntown && Coordinates.Y <= -8;
    const bool bIndustrial = !bDowntown && !bWaterfront && Coordinates.X >= 8 && Coordinates.Y >= 5;

    const float RoadHalf = RoadWidth * 0.5f;
    const float HalfCell = CellSpacing * 0.5f;
    const float SegmentLength = HalfCell - RoadHalf;
    const float SegmentCenter = (HalfCell + RoadHalf) * 0.5f;

    // Asphalt intersection and its east/west road segments.
    AddCube(RoadInstances, FVector(0.0f, 0.0f, -18.0f), FVector(RoadWidth, CellSpacing, 36.0f));
    AddCube(RoadInstances, FVector(-SegmentCenter, 0.0f, -18.0f), FVector(SegmentLength, RoadWidth, 36.0f));
    AddCube(RoadInstances, FVector(SegmentCenter, 0.0f, -18.0f), FVector(SegmentLength, RoadWidth, 36.0f));

    // Raised sidewalks frame the block perimeter without covering the road.
    const float SidewalkWidth = 900.0f;
    const float SidewalkCenter = RoadHalf + SidewalkWidth * 0.5f + 50.0f;
    const float SidewalkLength = CellSpacing - RoadWidth - 50.0f;
    const float FarSidewalkCenter = CellSpacing - SidewalkCenter;

    AddCube(SidewalkInstances, FVector(SidewalkCenter, HalfCell, 9.0f), FVector(SidewalkWidth, SidewalkLength, 18.0f));
    AddCube(SidewalkInstances, FVector(FarSidewalkCenter, HalfCell, 9.0f), FVector(SidewalkWidth, SidewalkLength, 18.0f));
    AddCube(SidewalkInstances, FVector(HalfCell, SidewalkCenter, 9.0f), FVector(SidewalkLength, SidewalkWidth, 18.0f));
    AddCube(SidewalkInstances, FVector(HalfCell, FarSidewalkCenter, 9.0f), FVector(SidewalkLength, SidewalkWidth, 18.0f));

    // Low curbs visually separate asphalt and sidewalk. They remain part of
    // the sidewalk HISM so no extra draw component is introduced.
    AddCube(SidewalkInstances, FVector(SidewalkCenter - SidewalkWidth * 0.5f + 45.0f, HalfCell, 20.0f), FVector(90.0f, SidewalkLength, 22.0f));
    AddCube(SidewalkInstances, FVector(FarSidewalkCenter + SidewalkWidth * 0.5f - 45.0f, HalfCell, 20.0f), FVector(90.0f, SidewalkLength, 22.0f));
    AddCube(SidewalkInstances, FVector(HalfCell, SidewalkCenter - SidewalkWidth * 0.5f + 45.0f, 20.0f), FVector(SidewalkLength, 90.0f, 22.0f));
    AddCube(SidewalkInstances, FVector(HalfCell, FarSidewalkCenter + SidewalkWidth * 0.5f - 45.0f, 20.0f), FVector(SidewalkLength, 90.0f, 22.0f));

    // Dashed yellow center lines and white zebra crossings use separate HISM batches.
    for (float Position = 1200.0f; Position < HalfCell - 900.0f; Position += 950.0f)
    {
        AddCube(LaneLineInstances, FVector(Position, 0.0f, 1.0f), FVector(420.0f, 42.0f, 3.0f));
        AddCube(LaneLineInstances, FVector(-Position, 0.0f, 1.0f), FVector(420.0f, 42.0f, 3.0f));
        AddCube(LaneLineInstances, FVector(0.0f, Position, 1.0f), FVector(42.0f, 420.0f, 3.0f));
        AddCube(LaneLineInstances, FVector(0.0f, -Position, 1.0f), FVector(42.0f, 420.0f, 3.0f));
    }

    // Zebra crossings on all four approaches.
    for (int32 Stripe = 0; Stripe < 6; ++Stripe)
    {
        const float Offset = 1100.0f + static_cast<float>(Stripe) * 155.0f;
        for (int32 Side : { -1, 1 })
        {
            AddCube(CrosswalkInstances, FVector(Side * Offset, 0.0f, 2.0f), FVector(88.0f, RoadWidth - 180.0f, 4.0f));
            AddCube(CrosswalkInstances, FVector(0.0f, Side * Offset, 2.0f), FVector(RoadWidth - 180.0f, 88.0f, 4.0f));
        }
    }

    // Low-poly street trees sit on the outer edge of the sidewalk, leaving
    // the pedestrian patrol line clear.
    const FVector TreeLocations[] =
    {
        FVector(1650.0f, 5500.0f, 0.0f), FVector(1650.0f, 12500.0f, 0.0f),
        FVector(16350.0f, 5500.0f, 0.0f), FVector(16350.0f, 12500.0f, 0.0f),
        FVector(5500.0f, 1650.0f, 0.0f), FVector(12500.0f, 1650.0f, 0.0f),
        FVector(5500.0f, 16350.0f, 0.0f), FVector(12500.0f, 16350.0f, 0.0f)
    };

    for (const FVector& TreeLocation : TreeLocations)
    {
        // Waterfront-side entries would sit on the seawall or water plane;
        // keep only the inland street trees in coastal cells.
        if (bWaterfront && TreeLocation.Y > 6000.0f)
        {
            continue;
        }

        AddMeshInstance(TreeTrunkInstances, CylinderMesh, TreeLocation + FVector(0.0f, 0.0f, 228.0f), FVector(80.0f, 80.0f, 420.0f));
        AddMeshInstance(TreeCanopyInstances, SphereMesh, TreeLocation + FVector(0.0f, 0.0f, 460.0f), FVector(560.0f, 560.0f, 440.0f));
    }

    // Waterfront cells reserve the outer half of the block for a simple
    // promenade, seawall and opaque water placeholder. Keeping water opaque
    // avoids the fill-rate cost of large translucent surfaces on mobile.
    if (bWaterfront)
    {
        AddCube(SidewalkInstances, FVector(HalfCell, CellSpacing * 0.63f, 9.0f), FVector(CellSpacing - 4000.0f, 760.0f, 18.0f));
        AddCube(TrimInstances, FVector(HalfCell, CellSpacing * 0.668f, 45.0f), FVector(CellSpacing - 4000.0f, 80.0f, 70.0f));

        // Break the water edge into three overlapping deterministic spans.
        // The small overlap prevents visible gaps between adjacent segments;
        // global segment indices keep the shoreline profile stable when cells
        // stream out and back in.
        const float CoastSpan = CellSpacing - 4000.0f;
        const float CoastSegmentStep = CoastSpan / 3.0f;
        const float CoastSegmentWidth = CoastSegmentStep + 120.0f;
        const float OceanEdgeY = 0.902f;
        const float LandwardShoreBaseY = 0.674f;
        for (int32 SegmentIndex = 0; SegmentIndex < 3; ++SegmentIndex)
        {
            const int32 GlobalCoastSegment = Coordinates.X * 3 + SegmentIndex;
            const float CoastPhase = static_cast<float>(GlobalCoastSegment);
            const float ShorelineY = 0.735f
                + 0.018f * FMath::Sin(CoastPhase * 0.62f)
                + 0.012f * FMath::Sin(CoastPhase * 0.21f + 1.3f);
            const float SegmentCenterX = 2000.0f + (static_cast<float>(SegmentIndex) + 0.5f) * CoastSegmentStep;
            const float WaterDepth = (OceanEdgeY - ShorelineY) * CellSpacing;
            const float WaterCenterY = (OceanEdgeY + ShorelineY) * 0.5f * CellSpacing;
            const float SandDepth = (ShorelineY - LandwardShoreBaseY) * CellSpacing;
            const float SandCenterY = (ShorelineY + LandwardShoreBaseY) * 0.5f * CellSpacing;

            AddCube(SidewalkInstances, FVector(SegmentCenterX, SandCenterY, 8.0f),
                FVector(CoastSegmentWidth, SandDepth, 16.0f));
            AddCube(WaterInstances, FVector(SegmentCenterX, WaterCenterY, -12.0f),
                FVector(CoastSegmentWidth, WaterDepth, 24.0f));
            AddCube(CrosswalkInstances, FVector(SegmentCenterX, ShorelineY * CellSpacing + 25.0f, 3.0f),
                FVector(CoastSegmentStep - 40.0f, 70.0f, 6.0f));
        }

        // A compact coastal park occupies the strip between the low-rise
        // buildings and promenade. Flattened foliage spheres act as low
        // planting beds without adding another component or material batch.
        AddMeshInstance(TreeCanopyInstances, SphereMesh,
            FVector(CellSpacing * 0.28f, CellSpacing * 0.535f, 65.0f), FVector(2600.0f, 820.0f, 130.0f));
        AddMeshInstance(TreeCanopyInstances, SphereMesh,
            FVector(CellSpacing * 0.72f, CellSpacing * 0.535f, 65.0f), FVector(2600.0f, 820.0f, 130.0f));

        // Stylized low-poly palms reuse the existing trunk/canopy batches.
        // Four flattened crown lobes read as a simple radial frond silhouette.
        const FVector CoastalPalmLocations[] =
        {
            FVector(CellSpacing * 0.18f, CellSpacing * 0.545f, 0.0f),
            FVector(CellSpacing * 0.50f, CellSpacing * 0.545f, 0.0f),
            FVector(CellSpacing * 0.82f, CellSpacing * 0.545f, 0.0f)
        };
        for (const FVector& PalmLocation : CoastalPalmLocations)
        {
            AddMeshInstance(TreeTrunkInstances, CylinderMesh,
                PalmLocation + FVector(0.0f, 0.0f, 875.0f), FVector(130.0f, 130.0f, 1750.0f));
            AddMeshInstance(TreeCanopyInstances, SphereMesh,
                PalmLocation + FVector(-340.0f, 0.0f, 1710.0f), FVector(950.0f, 260.0f, 180.0f));
            AddMeshInstance(TreeCanopyInstances, SphereMesh,
                PalmLocation + FVector(340.0f, 0.0f, 1710.0f), FVector(950.0f, 260.0f, 180.0f));
            AddMeshInstance(TreeCanopyInstances, SphereMesh,
                PalmLocation + FVector(0.0f, -340.0f, 1710.0f), FVector(260.0f, 950.0f, 180.0f));
            AddMeshInstance(TreeCanopyInstances, SphereMesh,
                PalmLocation + FVector(0.0f, 340.0f, 1710.0f), FVector(260.0f, 950.0f, 180.0f));
            AddMeshInstance(TreeCanopyInstances, SphereMesh,
                PalmLocation + FVector(0.0f, 0.0f, 1800.0f), FVector(360.0f, 360.0f, 300.0f));
        }

        // Simple bench props use the existing trim batch and stay clear of
        // the promenade's pedestrian path.
        const FVector BenchLocations[] =
        {
            FVector(CellSpacing * 0.34f, CellSpacing * 0.585f, 0.0f),
            FVector(CellSpacing * 0.66f, CellSpacing * 0.585f, 0.0f)
        };
        for (const FVector& BenchLocation : BenchLocations)
        {
            AddCube(TrimInstances, BenchLocation + FVector(0.0f, 0.0f, 125.0f), FVector(1200.0f, 300.0f, 70.0f));
            AddCube(TrimInstances, BenchLocation + FVector(0.0f, 145.0f, 360.0f), FVector(1200.0f, 70.0f, 430.0f));
            AddCube(TrimInstances, BenchLocation + FVector(-480.0f, 0.0f, 55.0f), FVector(90.0f, 220.0f, 110.0f));
            AddCube(TrimInstances, BenchLocation + FVector(480.0f, 0.0f, 55.0f), FVector(90.0f, 220.0f, 110.0f));
        }

        // Unlit-looking placeholder lamp posts establish a readable rhythm
        // along the park edge; actual emissive lights can replace them later.
        const FVector ParkLightLocations[] =
        {
            FVector(CellSpacing * 0.18f, CellSpacing * 0.598f, 0.0f),
            FVector(CellSpacing * 0.50f, CellSpacing * 0.598f, 0.0f),
            FVector(CellSpacing * 0.82f, CellSpacing * 0.598f, 0.0f)
        };
        for (const FVector& LightLocation : ParkLightLocations)
        {
            AddCube(TrimInstances, LightLocation + FVector(0.0f, 0.0f, 300.0f), FVector(80.0f, 80.0f, 600.0f));
            AddCube(TrimInstances, LightLocation + FVector(0.0f, 0.0f, 650.0f), FVector(260.0f, 260.0f, 120.0f));
        }
    }

    // One deterministic north-east block per intersection.
    const uint32 Seed = GetTypeHash(Coordinates) ^ 0x9E3779B9u;
    // District identity is coordinate-derived, so the same world location
    // always recreates the same skyline after a cell is streamed back in.
    const float HeightBase = bDowntown ? 9000.0f : (bWaterfront ? 3200.0f : (bIndustrial ? 2600.0f : 4200.0f));
    const float HeightRange = bDowntown ? 15000.0f : (bWaterfront ? 5200.0f : (bIndustrial ? 3000.0f : 9500.0f));
    const float WidthBase = bIndustrial ? 5000.0f : (bWaterfront ? 3000.0f : 2800.0f);
    const float WidthRange = bIndustrial ? 1200.0f : (bWaterfront ? 1300.0f : 1800.0f);
    const float DepthBase = bIndustrial ? 4800.0f : (bWaterfront ? 2800.0f : 2800.0f);
    const float DepthRange = bIndustrial ? 1400.0f : (bWaterfront ? 1300.0f : 1800.0f);

    const FVector BuildingLocations[] =
    {
        FVector(CellSpacing * 0.27f, CellSpacing * 0.27f, 0.0f),
        FVector(CellSpacing * 0.73f, CellSpacing * 0.27f, 0.0f),
        FVector(CellSpacing * 0.50f, CellSpacing * 0.73f, 0.0f)
    };

    for (int32 Index = 0; Index < UE_ARRAY_COUNT(BuildingLocations); ++Index)
    {
        const uint32 BuildingSeed = Seed + static_cast<uint32>(Index) * 0x85EBCA6Bu;
        const float Width = WidthBase + static_cast<float>((BuildingSeed >> 3) % static_cast<uint32>(WidthRange));
        const float Depth = DepthBase + static_cast<float>((BuildingSeed >> 11) % static_cast<uint32>(DepthRange));
        const float Height = HeightBase + static_cast<float>((BuildingSeed >> 19) % static_cast<uint32>(HeightRange));

        FVector BuildingLocation = BuildingLocations[Index];
        if (bWaterfront)
        {
            const float WaterfrontX[] = { 0.25f, 0.72f, 0.48f };
            const float WaterfrontY[] = { 0.22f, 0.22f, 0.38f };
            BuildingLocation.X = CellSpacing * WaterfrontX[Index];
            BuildingLocation.Y = CellSpacing * WaterfrontY[Index];
        }
        BuildingLocation.Z = Height * 0.5f;
        AddCube(BuildingInstances, BuildingLocation, FVector(Width, Depth, Height));

        // Flat facade glazing is kept in a separate non-colliding HISM.
        // Two columns by up to three rows per side keep the instance count low.
        const float WindowWidth = 220.0f;
        const float WindowHeight = 240.0f;
        const float WindowInset = 8.0f;
        const float ColumnOffsets[] = { -0.22f, 0.22f };
        const float FloorOffsets[] = { 0.24f, 0.48f, 0.72f };

        for (float Column : ColumnOffsets)
        {
            for (float Floor : FloorOffsets)
            {
                const float WindowZ = Height * Floor;
                const float XOffset = Column * Width;
                const float YOffset = Column * Depth;

                AddCube(GlassInstances,
                    BuildingLocation + FVector(XOffset, Depth * 0.5f + WindowInset, WindowZ - BuildingLocation.Z),
                    FVector(WindowWidth, 24.0f, WindowHeight));
                AddCube(GlassInstances,
                    BuildingLocation + FVector(XOffset, -Depth * 0.5f - WindowInset, WindowZ - BuildingLocation.Z),
                    FVector(WindowWidth, 24.0f, WindowHeight));
                AddCube(GlassInstances,
                    BuildingLocation + FVector(Width * 0.5f + WindowInset, YOffset, WindowZ - BuildingLocation.Z),
                    FVector(24.0f, WindowWidth, WindowHeight));
                AddCube(GlassInstances,
                    BuildingLocation + FVector(-Width * 0.5f - WindowInset, YOffset, WindowZ - BuildingLocation.Z),
                    FVector(24.0f, WindowWidth, WindowHeight));
            }
        }

        // Roof parapet and a restrained facade belt add silhouette detail.
        AddCube(TrimInstances, BuildingLocation + FVector(0.0f, 0.0f, Height * 0.5f - 60.0f), FVector(Width + 100.0f, Depth + 100.0f, 120.0f));
        AddCube(TrimInstances, BuildingLocation + FVector(0.0f, 0.0f, Height * 0.22f), FVector(Width + 30.0f, 55.0f, 45.0f));
    }
}
