#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "VICECityGenerator.generated.h"

class AVICECityChunk;
class AVICEPedestrian;

/**
 * Streams a deterministic graybox city around the currently possessed pawn.
 * World coordinates and cell dimensions are centimeters.
 */
UCLASS()
class PROJECTVICE_API AVICECityGenerator : public AActor
{
    GENERATED_BODY()

public:
    AVICECityGenerator();

    virtual void Tick(float DeltaSeconds) override;

protected:
    virtual void BeginPlay() override;

private:
    void UpdateStreaming();

    UPROPERTY(Transient)
    TMap<FIntPoint, TObjectPtr<AVICECityChunk>> ActiveChunks;

    UPROPERTY(Transient)
    TMap<FIntPoint, TObjectPtr<AVICEPedestrian>> ActivePedestrians;

    TArray<FIntPoint> PendingCells;

    UPROPERTY(EditDefaultsOnly, Category="VICE|Streaming", meta=(ClampMin="1", ClampMax="32"))
    int32 GridRadius = 12;

    UPROPERTY(EditDefaultsOnly, Category="VICE|Streaming", meta=(ClampMin="1", ClampMax="4"))
    int32 StreamingRadius = 2;

    UPROPERTY(EditDefaultsOnly, Category="VICE|City", meta=(ClampMin="10000.0"))
    float BlockSpacing = 18000.0f;

    UPROPERTY(EditDefaultsOnly, Category="VICE|City", meta=(ClampMin="800.0"))
    float RoadWidth = 1600.0f;
};
