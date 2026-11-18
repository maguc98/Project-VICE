#include "VICECityGenerator.h"
#include "VICECityChunk.h"
#include "VICEPedestrian.h"
#include "VICETrafficVehicle.h"
#include "Engine/World.h"
#include "GameFramework/Pawn.h"
#include "GameFramework/PlayerController.h"

AVICECityGenerator::AVICECityGenerator()
{
    PrimaryActorTick.bCanEverTick = true;
    PrimaryActorTick.TickInterval = 0.25f;
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
            if (TObjectPtr<AVICEPedestrian>* Pedestrian = ActivePedestrians.Find(It.Key()))
            {
                if (IsValid(*Pedestrian))
                {
                    (*Pedestrian)->Destroy();
                }
                ActivePedestrians.Remove(It.Key());
            }
            if (TObjectPtr<AVICETrafficVehicle>* Traffic = ActiveTraffic.Find(It.Key()))
            {
                if (IsValid(*Traffic))
                {
                    (*Traffic)->Destroy();
                }
                ActiveTraffic.Remove(It.Key());
            }
            It.RemoveCurrent();
        }
    }

    // Discard queued cells that are no longer needed, then queue new cells
    // nearest-first so the road beneath the player is always the first to load.
    PendingCells.RemoveAll([&](const FIntPoint& Cell)
    {
        return !DesiredCells.Contains(Cell) || ActiveChunks.Contains(Cell);
    });

    TArray<FIntPoint> SortedDesiredCells = DesiredCells.Array();
    SortedDesiredCells.Sort([&](const FIntPoint& A, const FIntPoint& B)
    {
        const int32 DistanceA = FMath::Square(A.X - CenterCell.X) + FMath::Square(A.Y - CenterCell.Y);
        const int32 DistanceB = FMath::Square(B.X - CenterCell.X) + FMath::Square(B.Y - CenterCell.Y);
        return DistanceA < DistanceB;
    });

    for (const FIntPoint& Cell : SortedDesiredCells)
    {
        if (!ActiveChunks.Contains(Cell) && !PendingCells.Contains(Cell))
        {
            PendingCells.Add(Cell);
        }
    }

    // Spawn a small batch each update to reduce single-frame spikes on A14.
    constexpr int32 MaxChunksPerUpdate = 3;
    int32 SpawnedThisUpdate = 0;

    while (PendingCells.Num() > 0 && SpawnedThisUpdate < MaxChunksPerUpdate)
    {
        const FIntPoint Cell = PendingCells[0];
        PendingCells.RemoveAt(0);

        if (!DesiredCells.Contains(Cell) || ActiveChunks.Contains(Cell))
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

            AVICEPedestrian* Pedestrian = World->SpawnActor<AVICEPedestrian>(
                AVICEPedestrian::StaticClass(),
                CellOrigin + FVector(1300.0f, 1300.0f, 110.0f),
                FRotator::ZeroRotator,
                SpawnParameters);
            if (Pedestrian)
            {
                Pedestrian->InitializePatrol(CellOrigin, BlockSpacing, GetTypeHash(Cell));
                ActivePedestrians.Add(Cell, Pedestrian);
            }

            // A sparse deterministic pattern keeps ambient traffic count low
            // while making different active neighborhoods feel populated.
            if (FMath::Abs(Cell.X * 7 + Cell.Y * 11) % 4 == 0)
            {
                AVICETrafficVehicle* TrafficVehicle = World->SpawnActor<AVICETrafficVehicle>(
                    AVICETrafficVehicle::StaticClass(),
                    CellOrigin + FVector(450.0f, 450.0f, 42.0f),
                    FRotator::ZeroRotator,
                    SpawnParameters);
                if (TrafficVehicle)
                {
                    TrafficVehicle->InitializeRoute(CellOrigin, BlockSpacing, GetTypeHash(Cell));
                    ActiveTraffic.Add(Cell, TrafficVehicle);
                }
            }

            ++SpawnedThisUpdate;
        }
    }
}
