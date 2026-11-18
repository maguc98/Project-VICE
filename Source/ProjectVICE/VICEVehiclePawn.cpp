#include "VICEVehiclePawn.h"
#include "VICECharacter.h"
#include "Camera/CameraComponent.h"
#include "Components/BoxComponent.h"
#include "Components/StaticMeshComponent.h"
#include "GameFramework/PlayerController.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "Components/InputComponent.h"
#include "GameFramework/SpringArmComponent.h"
#include "UObject/ConstructorHelpers.h"

AVICEVehiclePawn::AVICEVehiclePawn()
{
    PrimaryActorTick.bCanEverTick = true;

    CollisionBody = CreateDefaultSubobject<UBoxComponent>(TEXT("VehicleCollision"));
    RootComponent = CollisionBody;
    CollisionBody->SetBoxExtent(FVector(210.0f, 95.0f, 48.0f));
    CollisionBody->SetRelativeLocation(FVector(0.0f, 0.0f, 58.0f));
    CollisionBody->SetCollisionProfileName(TEXT("BlockAllDynamic"));
    CollisionBody->SetGenerateOverlapEvents(true);

    ChassisMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Chassis"));
    ChassisMesh->SetupAttachment(CollisionBody);
    ChassisMesh->SetRelativeLocation(FVector(0.0f, 0.0f, 4.0f));
    ChassisMesh->SetRelativeScale3D(FVector(4.2f, 1.9f, 0.7f));
    ChassisMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);

    static ConstructorHelpers::FObjectFinder<UStaticMesh> CubeAsset(TEXT("/Engine/BasicShapes/Cube.Cube"));
    if (CubeAsset.Succeeded())
    {
        ChassisMesh->SetStaticMesh(CubeAsset.Object);
    }

    static ConstructorHelpers::FObjectFinder<UStaticMesh> CylinderAsset(TEXT("/Engine/BasicShapes/Cylinder.Cylinder"));
    const FVector WheelLocations[] =
    {
        FVector(132.0f, -100.0f, -32.0f),
        FVector(132.0f,  100.0f, -32.0f),
        FVector(-132.0f, -100.0f, -32.0f),
        FVector(-132.0f,  100.0f, -32.0f)
    };

    for (int32 Index = 0; Index < UE_ARRAY_COUNT(WheelLocations); ++Index)
    {
        UStaticMeshComponent* Wheel = CreateDefaultSubobject<UStaticMeshComponent>(
            *FString::Printf(TEXT("Wheel_%d"), Index));
        Wheel->SetupAttachment(CollisionBody);
        Wheel->SetRelativeLocation(WheelLocations[Index]);
        Wheel->SetRelativeRotation(FRotator(90.0f, 0.0f, 0.0f));
        Wheel->SetRelativeScale3D(FVector(0.42f, 0.18f, 0.42f));
        Wheel->SetCollisionEnabled(ECollisionEnabled::NoCollision);
        if (CylinderAsset.Succeeded())
        {
            Wheel->SetStaticMesh(CylinderAsset.Object);
        }
        WheelMeshes.Add(Wheel);
    }

    CameraBoom = CreateDefaultSubobject<USpringArmComponent>(TEXT("VehicleCameraBoom"));
    CameraBoom->SetupAttachment(CollisionBody);
    CameraBoom->SetRelativeLocation(FVector(0.0f, 0.0f, -25.0f));
    CameraBoom->TargetArmLength = 560.0f;
    CameraBoom->SocketOffset = FVector(0.0f, 0.0f, 115.0f);
    CameraBoom->bUsePawnControlRotation = true;
    CameraBoom->bEnableCameraLag = true;
    CameraBoom->CameraLagSpeed = 7.0f;
    CameraBoom->bDoCollisionTest = true;

    FollowCamera = CreateDefaultSubobject<UCameraComponent>(TEXT("VehicleCamera"));
    FollowCamera->SetupAttachment(CameraBoom, USpringArmComponent::SocketName);
    FollowCamera->bUsePawnControlRotation = false;
}

void AVICEVehiclePawn::BeginPlay()
{
    Super::BeginPlay();
}

void AVICEVehiclePawn::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);

    if (!GetController())
    {
        CurrentSpeed = FMath::FInterpTo(CurrentSpeed, 0.0f, DeltaSeconds, 0.8f);
        return;
    }

    if (FMath::Abs(ThrottleInput) > 0.01f)
    {
        CurrentSpeed += ThrottleInput * Acceleration * DeltaSeconds;
    }
    else
    {
        CurrentSpeed = FMath::FInterpTo(CurrentSpeed, 0.0f, DeltaSeconds, bBrakeInput ? 7.0f : 0.75f);
    }

    if (bBrakeInput)
    {
        CurrentSpeed = FMath::FInterpTo(CurrentSpeed, 0.0f, DeltaSeconds, 7.0f);
    }

    CurrentSpeed = FMath::Clamp(CurrentSpeed, -MaximumReverseSpeed, MaximumForwardSpeed);

    const float SpeedRatio = FMath::Clamp(FMath::Abs(CurrentSpeed) / MaximumForwardSpeed, 0.0f, 1.0f);
    const float DirectionSign = CurrentSpeed < -1.0f ? -1.0f : 1.0f;
    const float YawDegreesPerSecond = SteeringInput * FMath::Lerp(0.0f, 42.0f, SpeedRatio) * DirectionSign;

    if (FMath::Abs(CurrentSpeed) > 2.0f)
    {
        AddActorLocalRotation(FRotator(0.0f, YawDegreesPerSecond * DeltaSeconds, 0.0f));
        FHitResult Hit;
        const FVector Travel = GetActorForwardVector() * CurrentSpeed * DeltaSeconds;
        AddActorWorldOffset(Travel, true, &Hit, ETeleportType::None);
        if (Hit.IsValidBlockingHit())
        {
            CurrentSpeed = 0.0f;
        }
    }

    WheelSpinDegrees = FMath::Fmod(WheelSpinDegrees + (CurrentSpeed / 22.0f) * DeltaSeconds * 57.29578f, 360.0f);
    for (int32 Index = 0; Index < WheelMeshes.Num(); ++Index)
    {
        if (UStaticMeshComponent* Wheel = WheelMeshes[Index])
        {
            const float SteeringYaw = Index < 2 ? SteeringInput * 24.0f : 0.0f;
            Wheel->SetRelativeRotation(FRotator(WheelSpinDegrees, 0.0f, SteeringYaw + 90.0f));
        }
    }
}

void AVICEVehiclePawn::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
    Super::SetupPlayerInputComponent(PlayerInputComponent);
    check(PlayerInputComponent);

    PlayerInputComponent->BindAxis(TEXT("MoveForward"), this, &AVICEVehiclePawn::ApplyThrottle);
    PlayerInputComponent->BindAxis(TEXT("MoveRight"), this, &AVICEVehiclePawn::ApplySteering);
    PlayerInputComponent->BindAxis(TEXT("LookYaw"), this, &AVICEVehiclePawn::LookYaw);
    PlayerInputComponent->BindAxis(TEXT("LookPitch"), this, &AVICEVehiclePawn::LookPitch);
    PlayerInputComponent->BindAction(TEXT("VehicleBrake"), IE_Pressed, this, &AVICEVehiclePawn::BrakePressed);
    PlayerInputComponent->BindAction(TEXT("VehicleBrake"), IE_Released, this, &AVICEVehiclePawn::BrakeReleased);
    PlayerInputComponent->BindAction(TEXT("InteractVehicle"), IE_Pressed, this, &AVICEVehiclePawn::ExitInput);
    PlayerInputComponent->BindAction(TEXT("ToggleCamera"), IE_Pressed, this, &AVICEVehiclePawn::ToggleCameraPerspective);
}

bool AVICEVehiclePawn::EnterVehicle(AVICECharacter* Character)
{
    if (!IsValid(Character) || OccupyingCharacter || !Character->GetController())
    {
        return false;
    }

    APlayerController* PC = Cast<APlayerController>(Character->GetController());
    if (!PC || !PC->IsLocalController())
    {
        return false;
    }

    OccupyingCharacter = Character;
    VehicleController = PC;

    Character->SetActorHiddenInGame(true);
    Character->SetActorEnableCollision(false);
    Character->SetActorTickEnabled(false);
    Character->GetCharacterMovement()->DisableMovement();

    PC->Possess(this);
    return GetController() == PC;
}

void AVICEVehiclePawn::ExitVehicle()
{
    if (!OccupyingCharacter || !VehicleController)
    {
        return;
    }

    AVICECharacter* Character = OccupyingCharacter;
    APlayerController* PC = VehicleController;

    const FVector ExitLocation = GetActorLocation() - GetActorRightVector() * 300.0f + FVector(0.0f, 0.0f, 100.0f);
    Character->SetActorLocation(ExitLocation, false, nullptr, ETeleportType::TeleportPhysics);
    Character->SetActorHiddenInGame(false);
    Character->SetActorEnableCollision(true);
    Character->SetActorTickEnabled(true);
    Character->GetCharacterMovement()->SetMovementMode(MOVE_Walking);
    Character->SetCurrentVehicle(nullptr);

    OccupyingCharacter = nullptr;
    VehicleController = nullptr;
    ThrottleInput = 0.0f;
    SteeringInput = 0.0f;
    bBrakeInput = false;
    CurrentSpeed = 0.0f;

    PC->Possess(Character);
}

void AVICEVehiclePawn::ToggleCameraPerspective()
{
    bFirstPerson = !bFirstPerson;
    CameraBoom->TargetArmLength = bFirstPerson ? 0.0f : 560.0f;
    CameraBoom->SocketOffset = bFirstPerson
        ? FVector(90.0f, 0.0f, 130.0f)
        : FVector(0.0f, 0.0f, 115.0f);
    FollowCamera->SetFieldOfView(bFirstPerson ? 92.0f : 85.0f);
}

void AVICEVehiclePawn::SetBrakeInput(bool bPressed)
{
    bBrakeInput = bPressed;
}

void AVICEVehiclePawn::ApplyThrottle(float Value)
{
    ThrottleInput = FMath::Clamp(Value, -1.0f, 1.0f);
}

void AVICEVehiclePawn::ApplySteering(float Value)
{
    SteeringInput = FMath::Clamp(Value, -1.0f, 1.0f);
}

void AVICEVehiclePawn::BrakePressed()
{
    SetBrakeInput(true);
}

void AVICEVehiclePawn::BrakeReleased()
{
    SetBrakeInput(false);
}

void AVICEVehiclePawn::ExitInput()
{
    ExitVehicle();
}

void AVICEVehiclePawn::LookYaw(float Value)
{
    AddControllerYawInput(Value);
}

void AVICEVehiclePawn::LookPitch(float Value)
{
    AddControllerPitchInput(Value);
}
