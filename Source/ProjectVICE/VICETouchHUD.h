#pragma once

#include "CoreMinimal.h"
#include "Blueprint/UserWidget.h"
#include "VICETouchHUD.generated.h"

class AVICECharacter;
class UButton;
class UCanvasPanel;

/** Runtime-built touch action buttons; movement/look remain on virtual sticks. */
UCLASS()
class PROJECTVICE_API UVICETouchHUD : public UUserWidget
{
    GENERATED_BODY()

public:
    void SetControlledCharacter(AVICECharacter* InCharacter);

protected:
    virtual void NativeConstruct() override;

private:
    UPROPERTY()
    TObjectPtr<AVICECharacter> ControlledCharacter;

    UFUNCTION()
    void OnCameraPressed();

    UFUNCTION()
    void OnVehiclePressed();

    UFUNCTION()
    void OnBrakePressed();

    UFUNCTION()
    void OnBrakeReleased();

    UFUNCTION()
    void OnJumpPressed();

    UFUNCTION()
    void OnJumpReleased();

    UFUNCTION()
    void OnSprintPressed();

    UFUNCTION()
    void OnSprintReleased();

    UButton* AddActionButton(const FString& Label, const FVector2D& Position, const FVector2D& Size);
};
