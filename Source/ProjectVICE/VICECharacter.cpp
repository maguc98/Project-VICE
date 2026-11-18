#include "VICECharacter.h"
#include "Camera/CameraComponent.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "GameFramework/SpringArmComponent.h"
#include "Components/InputComponent.h"

AVICECharacter::AVICECharacter()
{
    PrimaryActorTick.bCanEverTick = false;

    bUseControllerRotationYaw = false;
    GetCharacterMovement()->bOrientRotationToMovement = true;
    GetCharacterMovement()->RotationRate = FRotator(0.0f, 540.0f, 0.0f);
    GetCharacterMovement()->MaxWalkSpeed = 420.0f;
    GetCharacterMovement()->BrakingDecelerationWalking = 1800.0f;

    CameraBoom = CreateDefaultSubobject<USpringArmComponent>(TEXT("CameraBoom"));
    CameraBoom->SetupAttachment(RootComponent);
    CameraBoom->TargetArmLength = ThirdPersonArmLength;
    CameraBoom->bUsePawnControlRotation = true;
    CameraBoom->bEnableCameraLag = true;
    CameraBoom->CameraLagSpeed = 10.0f;
    CameraBoom->bDoCollisionTest = true;

    FollowCamera = CreateDefaultSubobject<UCameraComponent>(TEXT("FollowCamera"));
    FollowCamera->SetupAttachment(CameraBoom, USpringArmComponent::SocketName);
    FollowCamera->bUsePawnControlRotation = false;
}

void AVICECharacter::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
    Super::SetupPlayerInputComponent(PlayerInputComponent);
    check(PlayerInputComponent);

    PlayerInputComponent->BindAxis(TEXT("MoveForward"), this, &AVICECharacter::MoveForward);
    PlayerInputComponent->BindAxis(TEXT("MoveRight"), this, &AVICECharacter::MoveRight);
    PlayerInputComponent->BindAxis(TEXT("LookYaw"), this, &AVICECharacter::LookYaw);
    PlayerInputComponent->BindAxis(TEXT("LookPitch"), this, &AVICECharacter::LookPitch);
    PlayerInputComponent->BindAction(TEXT("Jump"), IE_Pressed, this, &ACharacter::Jump);
    PlayerInputComponent->BindAction(TEXT("Jump"), IE_Released, this, &ACharacter::StopJumping);
    PlayerInputComponent->BindAction(TEXT("ToggleCamera"), IE_Pressed, this, &AVICECharacter::ToggleCameraPerspective);
}

void AVICECharacter::MoveForward(float Value)
{
    if (Controller && FMath::Abs(Value) > KINDA_SMALL_NUMBER)
    {
        AddMovementInput(FRotationMatrix(Controller->GetControlRotation()).GetUnitAxis(EAxis::X), Value);
    }
}

void AVICECharacter::MoveRight(float Value)
{
    if (Controller && FMath::Abs(Value) > KINDA_SMALL_NUMBER)
    {
        AddMovementInput(FRotationMatrix(Controller->GetControlRotation()).GetUnitAxis(EAxis::Y), Value);
    }
}

void AVICECharacter::LookYaw(float Value)
{
    AddControllerYawInput(Value);
}

void AVICECharacter::LookPitch(float Value)
{
    AddControllerPitchInput(Value);
}

void AVICECharacter::ToggleCameraPerspective()
{
    bFirstPerson = !bFirstPerson;
    CameraBoom->TargetArmLength = bFirstPerson ? FirstPersonArmLength : ThirdPersonArmLength;
    FollowCamera->SetRelativeLocation(bFirstPerson ? FVector(0.0f, 0.0f, 68.0f) : FVector::ZeroVector);
    FollowCamera->SetFieldOfView(bFirstPerson ? 90.0f : 85.0f);
}
