#include "VICECityGenerator.h"
#include "VICECityChunk.h"
#include "Engine/World.h"
#include "GameFramework/Pawn.h"
#include "GameFramework/PlayerController.h"

AVICECityGenerator::AVICECityGenerator()
{
    PrimaryActorTick.bCanEverTick = true;
    PrimaryActorTick.TickInterval = 0.35f;
}

void AVICECityGenerator::BeginPlay()
{
    Super::BeginPlay();
    UpdateStreaming();
}

void AVICECityGenerator::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    UpdateStreaming();
}

void AVICECityGenerator::UpdateStreaming()
{
    UWorld* World = GetWorld();
    if (!World)
    {
        return;
    }

    APlayerController* PlayerController = World->GetFirstPlayerController();
    APawn* PlayerPawn = PlayerController ? PlayerController->GetPawn() : nullptr;
    if (!PlayerPawn)
    {
        return;
    }

    const FVector PlayerLocation = PlayerPawn->GetActorLocation();
    const FIntPoint CenterCell(
        FMath::RoundToInt(PlayerLocation.X / BlockSpacing),
        FMath::RoundToInt(PlayerLocation.Y / BlockSpacing));

    TSet<FIntPoint> DesiredCells;
    for (int32 OffsetX = -StreamingRadius; OffsetX <= StreamingRadius; ++OffsetX)
    {
        for (int32 OffsetY = -StreamingRadius; OffsetY <= StreamingRadius; ++OffsetY)
        {
            const FIntPoint Cell(CenterCell.X + OffsetX, CenterCell.Y + OffsetY);
            if (FMath::Abs(Cell.X) <= GridRadius && FMath::Abs(Cell.Y) <= GridRadius)
            {
                DesiredCells.Add(Cell);
            }
        }
    }

    // Unload cells that have moved outside the active streaming window.
    for (auto It = ActiveChunks.CreateIterator(); It; ++It)
    {
        if (!DesiredCells.Contains(It.Key()) || !IsValid(It.Value()))
        {
            if (IsValid(It.Value()))
            {
                It.Value()->Destroy();
            }
            It.RemoveCurrent();
        }
    }

    // Load nearby cells asynchronously with respect to gameplay; no blocking
    // level transition is shown to the player. Each chunk owns its own meshes.
    for (const FIntPoint& Cell : DesiredCells)
    {
        if (ActiveChunks.Contains(Cell))
        {
            continue;
        }

        const FVector CellOrigin(
            static_cast<float>(Cell.X) * BlockSpacing,
            static_cast<float>(Cell.Y) * BlockSpacing,
            0.0f);

        FActorSpawnParameters SpawnParameters;
        SpawnParameters.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;

        AVICECityChunk* Chunk = World->SpawnActor<AVICECityChunk>(
            AVICECityChunk::StaticClass(),
            CellOrigin,
            FRotator::ZeroRotator,
            SpawnParameters);

        if (Chunk)
        {
            Chunk->InitializeCell(Cell, BlockSpacing, RoadWidth);
            ActiveChunks.Add(Cell, Chunk);
        }
    }
}
