#include "VICECityGenerator.h"
#include "Components/StaticMeshComponent.h"
#include "Components/SceneComponent.h"
#include "UObject/ConstructorHelpers.h"

AVICECityGenerator::AVICECityGenerator()
{
    PrimaryActorTick.bCanEverTick = false;
    RootComponent = CreateDefaultSubobject<USceneComponent>(TEXT("Root"));

    static ConstructorHelpers::FObjectFinder<UStaticMesh> CubeAsset(TEXT("/Engine/BasicShapes/Cube.Cube"));
    if (CubeAsset.Succeeded())
    {
        CubeMesh = CubeAsset.Object;
    }
}

void AVICECityGenerator::BeginPlay()
{
    Super::BeginPlay();
    GenerateCity();
}

UStaticMeshComponent* AVICECityGenerator::AddBlock(
    const FVector& Location,
    const FVector& Dimensions,
    const FName& ComponentName)
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

    MeshComponent->SetupAttachment(GetRootComponent());
    MeshComponent->SetStaticMesh(CubeMesh);
    MeshComponent->SetMobility(EComponentMobility::Static);
    MeshComponent->SetCollisionProfileName(TEXT("BlockAll"));
    MeshComponent->SetWorldLocation(GetActorLocation() + Location);
    MeshComponent->SetWorldScale3D(Dimensions / 100.0f);
    MeshComponent->RegisterComponent();
    GeneratedComponents.Add(MeshComponent);
    return MeshComponent;
}

void AVICECityGenerator::GenerateCity()
{
    if (!CubeMesh)
    {
        UE_LOG(LogTemp, Error, TEXT("VICE city generator: engine cube mesh was not found."));
        return;
    }

    const int32 GridCount = FMath::Clamp(RoadGridCount, 3, 11);
    const float HalfSpan = (GridCount - 1) * BlockSpacing * 0.5f;
    const float RoadLength = (GridCount - 1) * BlockSpacing + RoadWidth * 2.0f;

    // Continuous road strips create a simple navigable street grid.
    for (int32 Index = 0; Index < GridCount; ++Index)
    {
        const float Coordinate = -HalfSpan + Index * BlockSpacing;

        AddBlock(
            FVector(Coordinate, 0.0f, -18.0f),
            FVector(RoadWidth, RoadLength, 36.0f),
            *FString::Printf(TEXT("Road_NS_%02d"), Index));

        AddBlock(
            FVector(0.0f, Coordinate, -18.0f),
            FVector(RoadLength, RoadWidth, 36.0f),
            *FString::Printf(TEXT("Road_EW_%02d"), Index));
    }

    // Deterministic blockout skyline. The origin remains a road intersection
    // so the default player spawn is clear of building collision.
    for (int32 X = 0; X < GridCount - 1; ++X)
    {
        for (int32 Y = 0; Y < GridCount - 1; ++Y)
        {
            const float CenterX = -HalfSpan + (X + 0.5f) * BlockSpacing;
            const float CenterY = -HalfSpan + (Y + 0.5f) * BlockSpacing;

            for (int32 Building = 0; Building < 3; ++Building)
            {
                const float OffsetX = (Building - 1) * 4200.0f;
                const float OffsetY = (Building % 2 == 0) ? -3600.0f : 3600.0f;
                const float Width = 2600.0f + ((X * 17 + Y * 11 + Building * 7) % 5) * 420.0f;
                const float Depth = 2600.0f + ((X * 13 + Y * 19 + Building * 3) % 4) * 500.0f;
                const float Height = 4200.0f + ((X * 29 + Y * 23 + Building * 31) % 13) * 850.0f;

                AddBlock(
                    FVector(CenterX + OffsetX, CenterY + OffsetY, Height * 0.5f),
                    FVector(Width, Depth, Height),
                    *FString::Printf(TEXT("Building_%02d_%02d_%02d"), X, Y, Building));
            }
        }
    }

    UE_LOG(
        LogTemp,
        Log,
        TEXT("VICE graybox city generated: %d roads per direction, %d building blocks."),
        GridCount,
        (GridCount - 1) * (GridCount - 1) * 3);
}
