#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "VICECityChunk.generated.h"

class UHierarchicalInstancedStaticMeshComponent;
class UMaterialInstanceDynamic;
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
    void AddCube(
        UHierarchicalInstancedStaticMeshComponent* Target,
        const FVector& LocalLocation,
        const FVector& Dimensions);

    UPROPERTY()
    TObjectPtr<USceneComponent> SceneRoot;

    UPROPERTY()
    TObjectPtr<UStaticMesh> CubeMesh;

    UPROPERTY()
    TObjectPtr<UHierarchicalInstancedStaticMeshComponent> RoadInstances;

    UPROPERTY()
    TObjectPtr<UHierarchicalInstancedStaticMeshComponent> SidewalkInstances;

    UPROPERTY()
    TObjectPtr<UHierarchicalInstancedStaticMeshComponent> BuildingInstances;

    UPROPERTY()
    TObjectPtr<UHierarchicalInstancedStaticMeshComponent> GlassInstances;

    UPROPERTY()
    TObjectPtr<UHierarchicalInstancedStaticMeshComponent> MarkingInstances;

    UPROPERTY()
    TObjectPtr<UHierarchicalInstancedStaticMeshComponent> TrimInstances;

    UPROPERTY(Transient)
    TObjectPtr<UMaterialInstanceDynamic> RoadMaterial;

    UPROPERTY(Transient)
    TObjectPtr<UMaterialInstanceDynamic> SidewalkMaterial;

    UPROPERTY(Transient)
    TObjectPtr<UMaterialInstanceDynamic> BuildingMaterial;

    UPROPERTY(Transient)
    TObjectPtr<UMaterialInstanceDynamic> GlassMaterial;

    UPROPERTY(Transient)
    TObjectPtr<UMaterialInstanceDynamic> MarkingMaterial;

    UPROPERTY(Transient)
    TObjectPtr<UMaterialInstanceDynamic> TrimMaterial;

    bool bInitialized = false;
};
