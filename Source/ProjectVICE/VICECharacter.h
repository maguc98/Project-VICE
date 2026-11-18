#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "VICECharacter.generated.h"

class UCameraComponent;
class USpringArmComponent;

/**
 * Lightweight third-person player pawn.
 * Input bindings are intentionally project-config driven so touch UI can call
 * the same movement/look functions from UMG or CommonUI later.
 */
UCLASS()
class PROJECTVICE_API AVICECharacter : public ACharacter
{
    GENERATED_BODY()

public:
    AVICECharacter();

    virtual void SetupPlayerInputComponent(class UInputComponent* PlayerInputComponent) override;

    UFUNCTION(BlueprintCallable, Category="VICE|Camera")
    void ToggleCameraPerspective();

    UFUNCTION(BlueprintCallable, Category="VICE|Movement")
    void MoveForward(float Value);

    UFUNCTION(BlueprintCallable, Category="VICE|Movement")
    void MoveRight(float Value);

    UFUNCTION(BlueprintCallable, Category="VICE|Movement")
    void LookYaw(float Value);

    UFUNCTION(BlueprintCallable, Category="VICE|Movement")
    void LookPitch(float Value);

protected:
    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="VICE|Camera")
    TObjectPtr<USpringArmComponent> CameraBoom;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="VICE|Camera")
    TObjectPtr<UCameraComponent> FollowCamera;

    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category="VICE|Camera", meta=(ClampMin="0.0"))
    float ThirdPersonArmLength = 320.0f;

    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category="VICE|Camera", meta=(ClampMin="0.0"))
    float FirstPersonArmLength = 0.0f;

private:
    bool bFirstPerson = false;
};
