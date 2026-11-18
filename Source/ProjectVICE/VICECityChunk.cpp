#include "VICECityChunk.h"
#include "Components/SceneComponent.h"
#include "Components/HierarchicalInstancedStaticMeshComponent.h"
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
    RootComponent = SceneRoot;

    RoadInstances = CreateDefaultSubobject<UHierarchicalInstancedStaticMeshComponent>(TEXT("RoadInstances"));
    RoadInstances->SetupAttachment(SceneRoot);
    RoadInstances->SetMobility(EComponentMobility::Static);
    RoadInstances->SetCollisionProfileName(TEXT("BlockAll"));

    SidewalkInstances = CreateDefaultSubobject<UHierarchicalInstancedStaticMeshComponent>(TEXT("SidewalkInstances"));
    SidewalkInstances->SetupAttachment(SceneRoot);
    SidewalkInstances->SetMobility(EComponentMobility::Static);
    SidewalkInstances->SetCollisionProfileName(TEXT("BlockAll"));

    BuildingInstances = CreateDefaultSubobject<UHierarchicalInstancedStaticMeshComponent>(TEXT("BuildingInstances"));
    BuildingInstances->SetupAttachment(SceneRoot);
    BuildingInstances->SetMobility(EComponentMobility::Static);
    BuildingInstances->SetCollisionProfileName(TEXT("BlockAll"));

    GlassInstances = CreateDefaultSubobject<UHierarchicalInstancedStaticMeshComponent>(TEXT("GlassInstances"));
    GlassInstances->SetupAttachment(SceneRoot);
    GlassInstances->SetMobility(EComponentMobility::Static);
    GlassInstances->SetCollisionEnabled(ECollisionEnabled::NoCollision);

    LaneLineInstances = CreateDefaultSubobject<UHierarchicalInstancedStaticMeshComponent>(TEXT("LaneLineInstances"));
    LaneLineInstances->SetupAttachment(SceneRoot);
    LaneLineInstances->SetMobility(EComponentMobility::Static);
    LaneLineInstances->SetCollisionEnabled(ECollisionEnabled::NoCollision);

    CrosswalkInstances = CreateDefaultSubobject<UHierarchicalInstancedStaticMeshComponent>(TEXT("CrosswalkInstances"));
    CrosswalkInstances->SetupAttachment(SceneRoot);
    CrosswalkInstances->SetMobility(EComponentMobility::Static);
    CrosswalkInstances->SetCollisionEnabled(ECollisionEnabled::NoCollision);

    TrimInstances = CreateDefaultSubobject<UHierarchicalInstancedStaticMeshComponent>(TEXT("TrimInstances"));
    TrimInstances->SetupAttachment(SceneRoot);
    TrimInstances->SetMobility(EComponentMobility::Static);
    TrimInstances->SetCollisionEnabled(ECollisionEnabled::NoCollision);

    static ConstructorHelpers::FObjectFinder<UStaticMesh> CubeAsset(TEXT("/Engine/BasicShapes/Cube.Cube"));
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
    }

    if (BasicMaterial.Succeeded())
    {
        BaseColorMaterial = BasicMaterial.Object;
    }
}

void AVICECityChunk::InitializeMaterials()
{
    if (!BaseColorMaterial)
    {
        return;
    }

    RoadMaterial = VICECityVisuals::MakeColorMaterial(BaseColorMaterial, this, FLinearColor(0.035f, 0.045f, 0.055f, 1.0f), 0.92f);
    SidewalkMaterial = VICECityVisuals::MakeColorMaterial(BaseColorMaterial, this, FLinearColor(0.34f, 0.36f, 0.37f, 1.0f), 0.86f);
    BuildingMaterial = VICECityVisuals::MakeColorMaterial(BaseColorMaterial, this, FLinearColor(0.62f, 0.59f, 0.52f, 1.0f), 0.82f);
    GlassMaterial = VICECityVisuals::MakeColorMaterial(BaseColorMaterial, this, FLinearColor(0.055f, 0.12f, 0.17f, 1.0f), 0.24f);
    LaneLineMaterial = VICECityVisuals::MakeColorMaterial(BaseColorMaterial, this, FLinearColor(0.96f, 0.72f, 0.18f, 1.0f), 0.72f);
    CrosswalkMaterial = VICECityVisuals::MakeColorMaterial(BaseColorMaterial, this, FLinearColor(0.92f, 0.93f, 0.88f, 1.0f), 0.78f);
    TrimMaterial = VICECityVisuals::MakeColorMaterial(BaseColorMaterial, this, FLinearColor(0.78f, 0.76f, 0.69f, 1.0f), 0.82f);

    RoadInstances->SetMaterial(0, RoadMaterial);
    SidewalkInstances->SetMaterial(0, SidewalkMaterial);
    BuildingInstances->SetMaterial(0, BuildingMaterial);
    GlassInstances->SetMaterial(0, GlassMaterial);
    LaneLineInstances->SetMaterial(0, LaneLineMaterial);
    CrosswalkInstances->SetMaterial(0, CrosswalkMaterial);
    TrimInstances->SetMaterial(0, TrimMaterial);
}

void AVICECityChunk::AddCube(
    UHierarchicalInstancedStaticMeshComponent* Target,
    const FVector& LocalLocation,
    const FVector& Dimensions)
{
    if (!Target || !CubeMesh)
    {
        return;
    }

    const FTransform InstanceTransform(
        FRotator::ZeroRotator,
        LocalLocation,
        Dimensions / 100.0f);

    Target->AddInstance(InstanceTransform);
}

void AVICECityChunk::InitializeCell(const FIntPoint& Coordinates, float CellSpacing, float RoadWidth)
{
    if (bInitialized || !RoadInstances || !SidewalkInstances || !BuildingInstances || !LaneLineInstances || !CrosswalkInstances || !CubeMesh)
    {
        return;
    }
    bInitialized = true;
    InitializeMaterials();

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

    // Dashed center lines on the roads. All markings share one HISM/material.
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

    // One deterministic north-east block per intersection.
    const uint32 Seed = GetTypeHash(Coordinates) ^ 0x9E3779B9u;
    const bool bDowntown = FMath::Abs(Coordinates.X) <= 2 && FMath::Abs(Coordinates.Y) <= 2;
    const float HeightBase = bDowntown ? 9000.0f : 4200.0f;
    const float HeightRange = bDowntown ? 15000.0f : 9500.0f;

    const FVector BuildingLocations[] =
    {
        FVector(CellSpacing * 0.27f, CellSpacing * 0.27f, 0.0f),
        FVector(CellSpacing * 0.73f, CellSpacing * 0.27f, 0.0f),
        FVector(CellSpacing * 0.50f, CellSpacing * 0.73f, 0.0f)
    };

    for (int32 Index = 0; Index < UE_ARRAY_COUNT(BuildingLocations); ++Index)
    {
        const uint32 BuildingSeed = Seed + static_cast<uint32>(Index) * 0x85EBCA6Bu;
        const float Width = 2800.0f + static_cast<float>((BuildingSeed >> 3) % 1800u);
        const float Depth = 2800.0f + static_cast<float>((BuildingSeed >> 11) % 1800u);
        const float Height = HeightBase + static_cast<float>((BuildingSeed >> 19) % static_cast<uint32>(HeightRange));

        FVector BuildingLocation = BuildingLocations[Index];
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
