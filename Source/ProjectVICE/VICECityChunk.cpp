#include "VICECityChunk.h"
#include "Components/SceneComponent.h"
#include "Components/StaticMeshComponent.h"
#include "UObject/ConstructorHelpers.h"

AVICECityChunk::AVICECityChunk()
{
    PrimaryActorTick.bCanEverTick = false;

    SceneRoot = CreateDefaultSubobject<USceneComponent>(TEXT("SceneRoot"));
    RootComponent = SceneRoot;

    static ConstructorHelpers::FObjectFinder<UStaticMesh> CubeAsset(TEXT("/Engine/BasicShapes/Cube.Cube"));
    if (CubeAsset.Succeeded())
    {
        CubeMesh = CubeAsset.Object;
    }
}

UStaticMeshComponent* AVICECityChunk::AddCube(
    const FVector& LocalLocation,
    const FVector& Dimensions,
    const FName& ComponentName,
    bool bBlocksMovement)
{
    if (!CubeMesh)
    {
        return nullptr;
    }

    UStaticMeshComponent* MeshComponent = NewObject<UStaticMeshComponent>(this, ComponentName);
    if (!MeshComponent)
    {
        return nullptr;
    }

    MeshComponent->SetupAttachment(SceneRoot);
    MeshComponent->SetStaticMesh(CubeMesh);
    MeshComponent->SetMobility(EComponentMobility::Static);
    MeshComponent->SetRelativeLocation(LocalLocation);
    MeshComponent->SetRelativeScale3D(Dimensions / 100.0f);
    MeshComponent->SetCollisionEnabled(bBlocksMovement ? ECollisionEnabled::QueryAndPhysics : ECollisionEnabled::NoCollision);
    if (bBlocksMovement)
    {
        MeshComponent->SetCollisionProfileName(TEXT("BlockAll"));
    }
    MeshComponent->RegisterComponent();
    return MeshComponent;
}

void AVICECityChunk::InitializeCell(const FIntPoint& Coordinates, float CellSpacing, float RoadWidth)
{
    if (bInitialized || !CubeMesh)
    {
        return;
    }
    bInitialized = true;

    const float RoadHalf = RoadWidth * 0.5f;
    const float HalfCell = CellSpacing * 0.5f;
    const float HorizontalSegmentLength = HalfCell - RoadHalf;
    const float HorizontalSegmentCenter = (HalfCell + RoadHalf) * 0.5f;

    // One north-south road segment and two east-west half-segments form a
    // cross intersection without overlapping coplanar road surfaces.
    AddCube(
        FVector(0.0f, 0.0f, -18.0f),
        FVector(RoadWidth, CellSpacing, 36.0f),
        TEXT("RoadNorthSouth"),
        true);

    AddCube(
        FVector(-HorizontalSegmentCenter, 0.0f, -18.0f),
        FVector(HorizontalSegmentLength, RoadWidth, 36.0f),
        TEXT("RoadWest"),
        true);

    AddCube(
        FVector(HorizontalSegmentCenter, 0.0f, -18.0f),
        FVector(HorizontalSegmentLength, RoadWidth, 36.0f),
        TEXT("RoadEast"),
        true);

    // Every intersection owns exactly one north-east block. Neighboring
    // chunks therefore never create duplicate buildings for the same block.
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

        AddCube(
            BuildingLocation,
            FVector(Width, Depth, Height),
            FName(*FString::Printf(TEXT("Building_%02d_%d_%d"), Index, Coordinates.X, Coordinates.Y)),
            true);
    }
}
