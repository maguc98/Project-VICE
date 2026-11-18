#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "VICECityGenerator.generated.h"

class UStaticMesh;
class UStaticMeshComponent;

/**
 * Runtime graybox city for the first playable build.
 * All dimensions are centimeters. Replace these primitives with streamed,
 * art-directed district assets as the world pipeline comes online.
 */
UCLASS()
class PROJECTVICE_API AVICECityGenerator : public AActor
{
    GENERATED_BODY()

public:
    AVICECityGenerator();

protected:
    virtual void BeginPlay() override;

private:
    void GenerateCity();
    UStaticMeshComponent* AddBlock(const FVector& Location, const FVector& Dimensions, const FName& ComponentName);

    UPROPERTY()
    TObjectPtr<UStaticMesh> CubeMesh;

    UPROPERTY(Transient)
    TArray<TObjectPtr<UStaticMeshComponent>> GeneratedComponents;

    UPROPERTY(EditDefaultsOnly, Category="VICE|City", meta=(ClampMin="3", ClampMax="11"))
    int32 RoadGridCount = 7;

    UPROPERTY(EditDefaultsOnly, Category="VICE|City", meta=(ClampMin="10000.0"))
    float BlockSpacing = 18000.0f;

    UPROPERTY(EditDefaultsOnly, Category="VICE|City", meta=(ClampMin="800.0"))
    float RoadWidth = 1600.0f;
};
