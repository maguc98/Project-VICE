#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "VICECityChunk.generated.h"

class UStaticMesh;
class USceneComponent;
class UStaticMeshComponent;

/** One streamed intersection and its north-east city block. */
UCLASS()
class PROJECTVICE_API AVICECityChunk : public AActor
{
    GENERATED_BODY()

public:
    AVICECityChunk();

    void InitializeCell(const FIntPoint& Coordinates, float CellSpacing, float RoadWidth);

private:
    UStaticMeshComponent* AddCube(
        const FVector& LocalLocation,
        const FVector& Dimensions,
        const FName& ComponentName,
        bool bBlocksMovement);

    UPROPERTY()
    TObjectPtr<USceneComponent> SceneRoot;

    UPROPERTY()
    TObjectPtr<UStaticMesh> CubeMesh;

    bool bInitialized = false;
};
