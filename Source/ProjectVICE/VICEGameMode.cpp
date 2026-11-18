#include "VICEGameMode.h"
#include "VICECharacter.h"
#include "VICECityGenerator.h"
#include "VICEVehiclePawn.h"
#include "Engine/World.h"
#include "GameFramework/PlayerStart.h"

AVICEGameMode::AVICEGameMode()
{
    DefaultPawnClass = AVICECharacter::StaticClass();
}

void AVICEGameMode::InitGame(const FString& MapName, const FString& Options, FString& ErrorMessage)
{
    Super::InitGame(MapName, Options, ErrorMessage);

    UWorld* World = GetWorld();
    if (!World)
    {
        return;
    }

    // Temporary runtime bootstrap keeps the prototype testable even before
    // the authored .umap and World Partition district pipeline are committed.
    World->SpawnActor<AVICECityGenerator>(
        AVICECityGenerator::StaticClass(),
        FVector::ZeroVector,
        FRotator::ZeroRotator);

    World->SpawnActor<AVICEVehiclePawn>(
        AVICEVehiclePawn::StaticClass(),
        FVector(550.0f, 0.0f, -4.0f),
        FRotator::ZeroRotator);

    World->SpawnActor<APlayerStart>(
        APlayerStart::StaticClass(),
        FVector(0.0f, 0.0f, 120.0f),
        FRotator::ZeroRotator);
}
