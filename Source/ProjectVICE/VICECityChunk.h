#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "VICECityChunk.generated.h"

class UHierarchicalInstancedStaticMeshComponent;
class USceneComponent;
class UStaticMesh;

/** One streamed intersection and its north-east city block. */
UCLASS()
class PROJECTVICE_API AVICECityChunk : public AActor
{
    GENERATED_BODY()

public:
    AVICECityChunk();

    void InitializeCell(const FIntPoint& Coordinates, float CellSpacing, float RoadWidth);

private:
    void AddCube(const FVector& LocalLocation, const FVector& Dimensions);

    UPROPERTY()
    TObjectPtr<USceneComponent> SceneRoot;

    UPROPERTY()
    TObjectPtr<UStaticMesh> CubeMesh;

    UPROPERTY()
    TObjectPtr<UHierarchicalInstancedStaticMeshComponent> CityInstances;

    bool bInitialized = false;
};
