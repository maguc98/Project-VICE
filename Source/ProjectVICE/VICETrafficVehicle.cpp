#include "VICETrafficVehicle.h"
#include "Components/BoxComponent.h"
#include "Components/StaticMeshComponent.h"
#include "UObject/ConstructorHelpers.h"
#include "Engine/World.h"
#include "GameFramework/PlayerController.h"
#include "GameFramework/Pawn.h"

AVICETrafficVehicle::AVICETrafficVehicle()
{
    PrimaryActorTick.bCanEverTick = true;
    PrimaryActorTick.TickInterval = 0.05f;

    CollisionBody = CreateDefaultSubobject<UBoxComponent>(TEXT("TrafficCollision"));
    RootComponent = CollisionBody;
    CollisionBody->SetBoxExtent(FVector(210.0f, 95.0f, 42.0f));
    CollisionBody->SetCollisionProfileName(TEXT("BlockAllDynamic"));
    CollisionBody->SetGenerateOverlapEvents(true);

    ChassisMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("TrafficChassis"));
    ChassisMesh->SetupAttachment(CollisionBody);
    ChassisMesh->SetRelativeScale3D(FVector(4.2f, 1.9f, 0.7f));
    ChassisMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);

    CabinMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("TrafficCabin"));
    CabinMesh->SetupAttachment(CollisionBody);
    CabinMesh->SetRelativeLocation(FVector(-20.0f, 0.0f, 48.0f));
    CabinMesh->SetRelativeScale3D(FVector(1.8f, 1.5f, 0.45f));
    CabinMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);

    static ConstructorHelpers::FObjectFinder<UStaticMesh> CubeAsset(TEXT("/Engine/BasicShapes/Cube.Cube"));
    if (CubeAsset.Succeeded())
    {
        ChassisMesh->SetStaticMesh(CubeAsset.Object);
        CabinMesh->SetStaticMesh(CubeAsset.Object);
    }
}

void AVICETrafficVehicle::InitializeRoute(const FVector& CellOrigin, float CellSpacing, uint32 RouteSeed)
{
    const float LaneOffset = 450.0f;
    const float Height = 42.0f;

    // A rectangular one-block loop follows the cross-street grid through
    // four intersections. All points remain inside road collision surfaces.
    const FVector Corners[] =
    {
        CellOrigin + FVector(LaneOffset, LaneOffset, Height),
        CellOrigin + FVector(CellSpacing + LaneOffset, LaneOffset, Height),
        CellOrigin + FVector(CellSpacing + LaneOffset, CellSpacing + LaneOffset, Height),
        CellOrigin + FVector(LaneOffset, CellSpacing + LaneOffset, Height)
    };

    const int32 StartCorner = static_cast<int32>(RouteSeed % UE_ARRAY_COUNT(Corners));
    const bool bReverse = (RouteSeed & 1u) != 0u;

    RoutePoints.Reset();
    for (int32 Index = 0; Index < UE_ARRAY_COUNT(Corners); ++Index)
    {
        const int32 CornerIndex = bReverse
            ? (StartCorner - Index + UE_ARRAY_COUNT(Corners)) % UE_ARRAY_COUNT(Corners)
            : (StartCorner + Index) % UE_ARRAY_COUNT(Corners);
        RoutePoints.Add(Corners[CornerIndex]);
    }

    CurrentRoutePoint = RoutePoints.Num() > 1 ? 1 : 0;
    if (RoutePoints.Num() > 0)
    {
        SetActorLocation(RoutePoints[0], false, nullptr, ETeleportType::TeleportPhysics);
    }
}

void AVICETrafficVehicle::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);

    if (APlayerController* PlayerController = GetWorld()->GetFirstPlayerController())
    {
        if (APawn* PlayerPawn = PlayerController->GetPawn())
        {
            const float DistanceSquared = FVector::DistSquared(GetActorLocation(), PlayerPawn->GetActorLocation());
            SetActorTickInterval(DistanceSquared > FMath::Square(22000.0f) ? 0.15f : 0.05f);
        }
    }

    if (RoutePoints.Num() < 2 || !RoutePoints.IsValidIndex(CurrentRoutePoint))
    {
        return;
    }

    FVector ToTarget = RoutePoints[CurrentRoutePoint] - GetActorLocation();
    ToTarget.Z = 0.0f;

    if (ToTarget.SizeSquared2D() < FMath::Square(220.0f))
    {
        CurrentRoutePoint = (CurrentRoutePoint + 1) % RoutePoints.Num();
        ToTarget = RoutePoints[CurrentRoutePoint] - GetActorLocation();
        ToTarget.Z = 0.0f;
    }

    const FVector Direction = ToTarget.GetSafeNormal2D();
    if (Direction.IsNearlyZero())
    {
        return;
    }

    SetActorRotation(Direction.Rotation());

    FHitResult Hit;
    AddActorWorldOffset(Direction * CruiseSpeed * DeltaSeconds, true, &Hit, ETeleportType::None);
    if (Hit.IsValidBlockingHit())
    {
        BlockedSeconds += DeltaSeconds;
        if (BlockedSeconds > 1.5f)
        {
            CurrentRoutePoint = (CurrentRoutePoint + 1) % RoutePoints.Num();
            BlockedSeconds = 0.0f;
        }
    }
    else
    {
        BlockedSeconds = 0.0f;
    }
}
