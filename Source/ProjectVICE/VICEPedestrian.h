#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "VICEPedestrian.generated.h"

class UCapsuleComponent;
class UStaticMeshComponent;

/** Lightweight sidewalk pedestrian prototype with a deterministic block loop. */
UCLASS()
class PROJECTVICE_API AVICEPedestrian : public AActor
{
    GENERATED_BODY()

public:
    AVICEPedestrian();

    virtual void Tick(float DeltaSeconds) override;

    void InitializePatrol(const FVector& CellOrigin, float CellSpacing, int32 RouteSeed);

private:
    UPROPERTY(VisibleAnywhere, Category="VICE|Pedestrian")
    TObjectPtr<UCapsuleComponent> CollisionCapsule;

    UPROPERTY(VisibleAnywhere, Category="VICE|Pedestrian")
    TObjectPtr<UStaticMeshComponent> BlockoutBody;

    UPROPERTY(EditDefaultsOnly, Category="VICE|Pedestrian", meta=(ClampMin="40.0", ClampMax="250.0"))
    float WalkSpeed = 125.0f;

    TArray<FVector> PatrolPoints;
    int32 CurrentPatrolPoint = 0;
};
