#include "VICEPedestrian.h"
#include "Components/CapsuleComponent.h"
#include "Components/StaticMeshComponent.h"
#include "UObject/ConstructorHelpers.h"
#include "Engine/World.h"
#include "GameFramework/PlayerController.h"
#include "GameFramework/Pawn.h"

AVICEPedestrian::AVICEPedestrian()
{
    PrimaryActorTick.bCanEverTick = true;
    PrimaryActorTick.TickInterval = 0.05f;

    CollisionCapsule = CreateDefaultSubobject<UCapsuleComponent>(TEXT("PedestrianCollision"));
    RootComponent = CollisionCapsule;
    CollisionCapsule->InitCapsuleSize(38.0f, 92.0f);
    CollisionCapsule->SetCollisionProfileName(TEXT("Pawn"));
    CollisionCapsule->SetGenerateOverlapEvents(true);

    BlockoutBody = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("PedestrianBody"));
    BlockoutBody->SetupAttachment(CollisionCapsule);
    BlockoutBody->SetRelativeLocation(FVector(0.0f, 0.0f, -2.0f));
    BlockoutBody->SetRelativeScale3D(FVector(0.62f, 0.62f, 1.05f));
    BlockoutBody->SetCollisionEnabled(ECollisionEnabled::NoCollision);

    static ConstructorHelpers::FObjectFinder<UStaticMesh> CapsuleAsset(TEXT("/Engine/BasicShapes/Capsule.Capsule"));
    if (CapsuleAsset.Succeeded())
    {
        BlockoutBody->SetStaticMesh(CapsuleAsset.Object);
    }
}

void AVICEPedestrian::InitializePatrol(const FVector& CellOrigin, float CellSpacing, uint32 RouteSeed)
{
    const float SidewalkInset = 1300.0f;
    const float FarSidewalk = CellSpacing - SidewalkInset;
    const float Height = 110.0f;

    // Deterministic route direction/starting corner per cell avoids every
    // pedestrian in the streamed view moving in lockstep.
    const FVector Corners[] =
    {
        CellOrigin + FVector(SidewalkInset, SidewalkInset, Height),
        CellOrigin + FVector(FarSidewalk, SidewalkInset, Height),
        CellOrigin + FVector(FarSidewalk, FarSidewalk, Height),
        CellOrigin + FVector(SidewalkInset, FarSidewalk, Height)
    };

    const int32 StartCorner = static_cast<int32>(RouteSeed % UE_ARRAY_COUNT(Corners));
    const bool bReverse = (RouteSeed & 1) != 0;

    PatrolPoints.Reset();
    for (int32 Index = 0; Index < UE_ARRAY_COUNT(Corners); ++Index)
    {
        const int32 CornerIndex = bReverse
            ? (StartCorner - Index + UE_ARRAY_COUNT(Corners)) % UE_ARRAY_COUNT(Corners)
            : (StartCorner + Index) % UE_ARRAY_COUNT(Corners);
        PatrolPoints.Add(Corners[CornerIndex]);
    }

    CurrentPatrolPoint = PatrolPoints.Num() > 1 ? 1 : 0;
    if (PatrolPoints.Num() > 0)
    {
        SetActorLocation(PatrolPoints[0], false, nullptr, ETeleportType::TeleportPhysics);
    }
}

void AVICEPedestrian::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);

    // Distant walkers update less often to reduce background simulation cost.
    if (APlayerController* PlayerController = GetWorld()->GetFirstPlayerController())
    {
        if (APawn* PlayerPawn = PlayerController->GetPawn())
        {
            const float DistanceSquared = FVector::DistSquared(GetActorLocation(), PlayerPawn->GetActorLocation());
            SetActorTickInterval(DistanceSquared > FMath::Square(22000.0f) ? 0.20f : 0.05f);
        }
    }

    if (PatrolPoints.Num() < 2 || !PatrolPoints.IsValidIndex(CurrentPatrolPoint))
    {
        return;
    }

    FVector ToTarget = PatrolPoints[CurrentPatrolPoint] - GetActorLocation();
    ToTarget.Z = 0.0f;

    if (ToTarget.SizeSquared2D() < FMath::Square(90.0f))
    {
        CurrentPatrolPoint = (CurrentPatrolPoint + 1) % PatrolPoints.Num();
        ToTarget = PatrolPoints[CurrentPatrolPoint] - GetActorLocation();
        ToTarget.Z = 0.0f;
    }

    const FVector Direction = ToTarget.GetSafeNormal2D();
    if (Direction.IsNearlyZero())
    {
        return;
    }

    SetActorRotation(Direction.Rotation());

    FHitResult Hit;
    AddActorWorldOffset(Direction * WalkSpeed * DeltaSeconds, true, &Hit, ETeleportType::None);
    if (Hit.IsValidBlockingHit())
    {
        // If the sidewalk is blocked, skip to the next waypoint rather than
        // spending CPU trying to push against the obstruction every frame.
        CurrentPatrolPoint = (CurrentPatrolPoint + 1) % PatrolPoints.Num();
    }
}
