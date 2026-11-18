#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "VICETrafficVehicle.generated.h"

class UBoxComponent;
class UStaticMeshComponent;

/** Low-cost ambient traffic car following a deterministic city-block loop. */
UCLASS()
class PROJECTVICE_API AVICETrafficVehicle : public AActor
{
    GENERATED_BODY()

public:
    AVICETrafficVehicle();

    virtual void Tick(float DeltaSeconds) override;

    void InitializeRoute(const FVector& CellOrigin, float CellSpacing, uint32 RouteSeed);

private:
    UPROPERTY(VisibleAnywhere, Category="VICE|Traffic")
    TObjectPtr<UBoxComponent> CollisionBody;

    UPROPERTY(VisibleAnywhere, Category="VICE|Traffic")
    TObjectPtr<UStaticMeshComponent> ChassisMesh;

    UPROPERTY(VisibleAnywhere, Category="VICE|Traffic")
    TObjectPtr<UStaticMeshComponent> CabinMesh;

    UPROPERTY(EditDefaultsOnly, Category="VICE|Traffic", meta=(ClampMin="100.0", ClampMax="1600.0"))
    float CruiseSpeed = 760.0f;

    TArray<FVector> RoutePoints;
    int32 CurrentRoutePoint = 0;
    float BlockedSeconds = 0.0f;
};
