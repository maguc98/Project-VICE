#include "VICEDayNightController.h"
#include "Components/DirectionalLightComponent.h"
#include "Components/SceneComponent.h"
#include "Components/SkyLightComponent.h"

AVICEDayNightController::AVICEDayNightController()
{
    PrimaryActorTick.bCanEverTick = true;
    PrimaryActorTick.TickInterval = 1.0f;

    SceneRoot = CreateDefaultSubobject<USceneComponent>(TEXT("SceneRoot"));
    RootComponent = SceneRoot;

    // Mobility is established in the component constructors. Setting it here
    // avoids changing a registered light's mobility from an editor script.
    SunLight = CreateDefaultSubobject<UDirectionalLightComponent>(TEXT("PreviewSun"));
    SunLight->SetupAttachment(SceneRoot);
    SunLight->SetMobility(EComponentMobility::Movable);
    SunLight->SetAtmosphereSunLight(true);
    SunLight->SetAtmosphereSunLightIndex(0);
    SunLight->SetIntensity(8.0f);

    SkyLight = CreateDefaultSubobject<USkyLightComponent>(TEXT("PreviewSkyLight"));
    SkyLight->SetupAttachment(SceneRoot);
    SkyLight->SetMobility(EComponentMobility::Movable);
    SkyLight->SetIntensity(1.0f);
}

void AVICEDayNightController::BeginPlay()
{
    Super::BeginPlay();
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

    SetActorRotation(FRotator(SunPitch, -35.0f, 0.0f));
    if (SunLight)
    {
        SunLight->SetIntensity(0.04f + MaximumSunIntensity * Daylight);
        SunLight->SetLightColor(SunColor);
    }

    if (SkyLight)
    {
        SkyLight->SetIntensity(0.18f + 0.82f * Daylight);
        SkyLight->SetLightColor(FMath::Lerp(
            FLinearColor(0.12f, 0.18f, 0.30f, 1.0f),
            FLinearColor(0.78f, 0.86f, 1.0f, 1.0f),
            Daylight));
    }
}
