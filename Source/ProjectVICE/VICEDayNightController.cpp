#include "VICEDayNightController.h"
#include "Engine/DirectionalLight.h"
#include "Engine/SkyLight.h"
#include "Components/DirectionalLightComponent.h"
#include "Components/SkyLightComponent.h"
#include "EngineUtils.h"
#include "EngineUtils.h"

AVICEDayNightController::AVICEDayNightController()
{
    PrimaryActorTick.bCanEverTick = true;
    PrimaryActorTick.TickInterval = 1.0f;
}

void AVICEDayNightController::BeginPlay()
{
    Super::BeginPlay();
    FindEnvironmentLights();
    UpdateLighting();
}

void AVICEDayNightController::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);

    const float SafeDayLength = FMath::Max(FullDayLengthSeconds, 60.0f);
    TimeOfDayHours = FMath::Fmod(TimeOfDayHours + (24.0f * DeltaSeconds / SafeDayLength), 24.0f);
    UpdateLighting();
}

void AVICEDayNightController::SetTimeOfDay(float Hours)
{
    TimeOfDayHours = FMath::Fmod(FMath::Max(Hours, 0.0f), 24.0f);
    UpdateLighting();
}

void AVICEDayNightController::FindEnvironmentLights()
{
    if (!GetWorld())
    {
        return;
    }

    for (TActorIterator<ADirectionalLight> It(GetWorld()); It; ++It)
    {
        SunActor = *It;
        break;
    }

    for (TActorIterator<ASkyLight> It(GetWorld()); It; ++It)
    {
        SkyActor = *It;
        break;
    }

    if (!SunActor)
    {
        UE_LOG(LogTemp, Warning, TEXT("VICE day/night: no DirectionalLight found in the current map."));
    }
    if (!SkyActor)
    {
        UE_LOG(LogTemp, Warning, TEXT("VICE day/night: no SkyLight found in the current map."));
    }
}

void AVICEDayNightController::UpdateLighting()
{
    const float SolarAngle = ((TimeOfDayHours - 6.0f) / 12.0f) * PI;
    const float SunElevation = FMath::Sin(SolarAngle);
    const float Daylight = FMath::Clamp(SunElevation, 0.0f, 1.0f);
    const float SunPitch = -SunElevation * 90.0f;

    // A slight warm tint at dawn/dusk and a cooler ambient sky at night.
    const FLinearColor NightSunColor(0.22f, 0.30f, 0.52f, 1.0f);
    const FLinearColor WarmSunColor(1.0f, 0.58f, 0.34f, 1.0f);
    const FLinearColor DaySunColor(1.0f, 0.94f, 0.82f, 1.0f);
    const float Warmth = 1.0f - FMath::Clamp(Daylight * 1.8f, 0.0f, 1.0f);
    const FLinearColor HorizonColor = FMath::Lerp(NightSunColor, WarmSunColor, FMath::Max(Daylight, 0.12f));
    const FLinearColor SunColor = FMath::Lerp(HorizonColor, DaySunColor, 1.0f - Warmth);

    if (SunActor)
    {
        SunActor->SetActorRotation(FRotator(SunPitch, -35.0f, 0.0f));
        if (UDirectionalLightComponent* SunComponent = SunActor->GetLightComponent())
        {
            SunComponent->SetIntensity(0.04f + MaximumSunIntensity * Daylight);
            SunComponent->SetLightColor(SunColor);
        }
    }

    if (SkyActor)
    {
        if (USkyLightComponent* SkyComponent = SkyActor->GetLightComponent())
        {
            SkyComponent->SetIntensity(0.18f + 0.82f * Daylight);
            SkyComponent->SetLightColor(FMath::Lerp(
                FLinearColor(0.12f, 0.18f, 0.30f, 1.0f),
                FLinearColor(0.78f, 0.86f, 1.0f, 1.0f),
                Daylight));
        }
    }
}
