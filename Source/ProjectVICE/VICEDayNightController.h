#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "VICEDayNightController.generated.h"

class ADirectionalLight;
class ASkyLight;

/** Lightweight mobile-friendly time-of-day driver for the map's sun and sky light. */
UCLASS()
class PROJECTVICE_API AVICEDayNightController : public AActor
{
    GENERATED_BODY()

public:
    AVICEDayNightController();

    virtual void Tick(float DeltaSeconds) override;

    UFUNCTION(BlueprintCallable, Category="VICE|Environment")
    void SetTimeOfDay(float Hours);

    UFUNCTION(BlueprintPure, Category="VICE|Environment")
    float GetTimeOfDayHours() const { return TimeOfDayHours; }

protected:
    virtual void BeginPlay() override;

private:
    void FindEnvironmentLights();
    void UpdateLighting();

    UPROPERTY(Transient)
    TObjectPtr<ADirectionalLight> SunActor;

    UPROPERTY(Transient)
    TObjectPtr<ASkyLight> SkyActor;

    UPROPERTY(EditAnywhere, Category="VICE|Environment", meta=(ClampMin="0.0", ClampMax="24.0"))
    float TimeOfDayHours = 14.0f;

    UPROPERTY(EditAnywhere, Category="VICE|Environment", meta=(ClampMin="60.0"))
    float FullDayLengthSeconds = 1200.0f;

    UPROPERTY(EditAnywhere, Category="VICE|Environment", meta=(ClampMin="0.0", ClampMax="20.0"))
    float MaximumSunIntensity = 8.0f;
};
