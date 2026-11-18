#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "VICECityChunk.generated.h"

class UHierarchicalInstancedStaticMeshComponent;
class UMaterialInstanceDynamic;
class UMaterialInterface;
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
    void AddMeshInstance(
        UHierarchicalInstancedStaticMeshComponent* Target,
        UStaticMesh* Mesh,
        const FVector& LocalLocation,
        const FVector& Dimensions);

    void AddCube(UHierarchicalInstancedStaticMeshComponent* Target, const FVector& LocalLocation, const FVector& Dimensions);

    UPROPERTY()
    TObjectPtr<USceneComponent> SceneRoot;

    UPROPERTY()
    TObjectPtr<UStaticMesh> CubeMesh;

    UPROPERTY()
    TObjectPtr<UStaticMesh> CylinderMesh;

    UPROPERTY()
    TObjectPtr<UStaticMesh> SphereMesh;

    UPROPERTY()
    TObjectPtr<UMaterialInterface> BaseColorMaterial;

    void InitializeMaterials(const FIntPoint& Coordinates);

    UPROPERTY()
    TObjectPtr<UHierarchicalInstancedStaticMeshComponent> RoadInstances;

    UPROPERTY()
    TObjectPtr<UHierarchicalInstancedStaticMeshComponent> SidewalkInstances;

    UPROPERTY()
    TObjectPtr<UHierarchicalInstancedStaticMeshComponent> BuildingInstances;

    UPROPERTY()
    TObjectPtr<UHierarchicalInstancedStaticMeshComponent> GlassInstances;

    UPROPERTY()
    TObjectPtr<UHierarchicalInstancedStaticMeshComponent> LaneLineInstances;

    UPROPERTY()
    TObjectPtr<UHierarchicalInstancedStaticMeshComponent> CrosswalkInstances;

    UPROPERTY()
    TObjectPtr<UHierarchicalInstancedStaticMeshComponent> TrimInstances;

    UPROPERTY()
    TObjectPtr<UHierarchicalInstancedStaticMeshComponent> TreeTrunkInstances;

    UPROPERTY()
    TObjectPtr<UHierarchicalInstancedStaticMeshComponent> TreeCanopyInstances;

    UPROPERTY(Transient)
    TObjectPtr<UMaterialInstanceDynamic> RoadMaterial;

    UPROPERTY(Transient)
    TObjectPtr<UMaterialInstanceDynamic> SidewalkMaterial;

    UPROPERTY(Transient)
    TObjectPtr<UMaterialInstanceDynamic> BuildingMaterial;

    UPROPERTY(Transient)
    TObjectPtr<UMaterialInstanceDynamic> GlassMaterial;

    UPROPERTY(Transient)
    TObjectPtr<UMaterialInstanceDynamic> LaneLineMaterial;

    UPROPERTY(Transient)
    TObjectPtr<UMaterialInstanceDynamic> CrosswalkMaterial;

    UPROPERTY(Transient)
    TObjectPtr<UMaterialInstanceDynamic> TrimMaterial;

    UPROPERTY(Transient)
    TObjectPtr<UMaterialInstanceDynamic> TreeTrunkMaterial;

    UPROPERTY(Transient)
    TObjectPtr<UMaterialInstanceDynamic> TreeCanopyMaterial;

    bool bInitialized = false;
};
