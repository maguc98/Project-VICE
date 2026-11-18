#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Pawn.h"
#include "VICEVehiclePawn.generated.h"

class AVICECharacter;
class APlayerController;
class UBoxComponent;
class UCameraComponent;
class USpringArmComponent;
class UStaticMeshComponent;

/**
 * Lightweight arcade vehicle prototype.
 * It uses swept kinematic movement instead of full Chaos suspension so the
 * first iPhone build can establish the driving loop before vehicle art/physics.
 */
UCLASS()
class PROJECTVICE_API AVICEVehiclePawn : public APawn
{
    GENERATED_BODY()

public:
    AVICEVehiclePawn();

    virtual void Tick(float DeltaSeconds) override;
    virtual void SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) override;

    UFUNCTION(BlueprintCallable, Category="VICE|Vehicle")
    bool EnterVehicle(AVICECharacter* Character);

    UFUNCTION(BlueprintCallable, Category="VICE|Vehicle")
    void ExitVehicle();

    UFUNCTION(BlueprintCallable, Category="VICE|Vehicle")
    void ToggleCameraPerspective();

    UFUNCTION(BlueprintCallable, Category="VICE|Vehicle")
    void SetBrakeInput(bool bPressed);

    UFUNCTION(BlueprintPure, Category="VICE|Vehicle")
    float GetSpeedKmh() const { return FMath::Abs(CurrentSpeed) * 0.036f; }

protected:
    virtual void BeginPlay() override;

private:
    void ApplyThrottle(float Value);
    void ApplySteering(float Value);
    void LookYaw(float Value);
    void LookPitch(float Value);
    void BrakePressed();
    void BrakeReleased();
    void ExitInput();

    UPROPERTY(VisibleAnywhere, Category="VICE|Vehicle")
    TObjectPtr<UBoxComponent> CollisionBody;

    UPROPERTY(VisibleAnywhere, Category="VICE|Vehicle")
    TObjectPtr<UStaticMeshComponent> ChassisMesh;

    UPROPERTY(VisibleAnywhere, Category="VICE|Vehicle")
    TObjectPtr<UStaticMeshComponent> CabinMesh;

    UPROPERTY(VisibleAnywhere, Category="VICE|Vehicle")
    TObjectPtr<UStaticMeshComponent> HoodMesh;

    UPROPERTY(VisibleAnywhere, Category="VICE|Vehicle")
    TObjectPtr<UStaticMeshComponent> TrunkMesh;

    UPROPERTY(VisibleAnywhere, Category="VICE|Vehicle")
    TObjectPtr<UStaticMeshComponent> FrontBumperMesh;

    UPROPERTY(VisibleAnywhere, Category="VICE|Vehicle")
    TObjectPtr<UStaticMeshComponent> RearBumperMesh;

    UPROPERTY(VisibleAnywhere, Category="VICE|Vehicle")
    TArray<TObjectPtr<UStaticMeshComponent>> WheelMeshes;

    UPROPERTY(VisibleAnywhere, Category="VICE|Camera")
    TObjectPtr<USpringArmComponent> CameraBoom;

    UPROPERTY(VisibleAnywhere, Category="VICE|Camera")
    TObjectPtr<UCameraComponent> FollowCamera;

    UPROPERTY(Transient)
    TObjectPtr<AVICECharacter> OccupyingCharacter;

    UPROPERTY(Transient)
    TObjectPtr<APlayerController> VehicleController;

    UPROPERTY(EditDefaultsOnly, Category="VICE|Vehicle", meta=(ClampMin="100.0"))
    float MaximumForwardSpeed = 3600.0f;

    UPROPERTY(EditDefaultsOnly, Category="VICE|Vehicle", meta=(ClampMin="100.0"))
    float MaximumReverseSpeed = 1200.0f;

    UPROPERTY(EditDefaultsOnly, Category="VICE|Vehicle", meta=(ClampMin="100.0"))
    float Acceleration = 2200.0f;

    float CurrentSpeed = 0.0f;
    float ThrottleInput = 0.0f;
    float SteeringInput = 0.0f;
    float WheelSpinDegrees = 0.0f;
    bool bBrakeInput = false;
    bool bFirstPerson = false;
};
