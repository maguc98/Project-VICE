#include "VICETouchHUD.h"
#include "VICECharacter.h"
#include "VICEVehiclePawn.h"
#include "Blueprint/WidgetTree.h"
#include "Components/CanvasPanel.h"
#include "Components/CanvasPanelSlot.h"
#include "Components/Button.h"
#include "Components/TextBlock.h"

void UVICETouchHUD::SetControlledCharacter(AVICECharacter* InCharacter)
{
    ControlledCharacter = InCharacter;
}

void UVICETouchHUD::NativeConstruct()
{
    Super::NativeConstruct();

    if (!WidgetTree)
    {
        return;
    }

    UCanvasPanel* RootCanvas = WidgetTree->ConstructWidget<UCanvasPanel>(UCanvasPanel::StaticClass(), TEXT("TouchRoot"));
    WidgetTree->RootWidget = RootCanvas;

    SpeedReadout = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("SpeedReadout"));
    SpeedReadout->SetText(FText::FromString(TEXT("VICE CITY")));
    SpeedReadout->SetJustification(ETextJustify::Right);
    UCanvasPanelSlot* SpeedSlot = RootCanvas->AddChildToCanvas(SpeedReadout);
    SpeedSlot->SetAnchors(FAnchors(1.0f, 0.0f, 1.0f, 0.0f));
    SpeedSlot->SetAlignment(FVector2D(1.0f, 0.0f));
    SpeedSlot->SetPosition(FVector2D(-30.0f, 28.0f));
    SpeedSlot->SetSize(FVector2D(210.0f, 48.0f));

    UButton* CameraButton = AddActionButton(TEXT("视角"), FVector2D(-112.0f, -220.0f), FVector2D(96.0f, 64.0f));
    if (CameraButton)
    {
        CameraButton->OnClicked.AddDynamic(this, &UVICETouchHUD::OnCameraPressed);
    }

    UButton* VehicleButton = AddActionButton(TEXT("上车 / 下车"), FVector2D(-238.0f, -220.0f), FVector2D(112.0f, 64.0f));
    if (VehicleButton)
    {
        VehicleButton->OnClicked.AddDynamic(this, &UVICETouchHUD::OnVehiclePressed);
    }

    UButton* JumpButton = AddActionButton(TEXT("跳跃"), FVector2D(-116.0f, -112.0f), FVector2D(104.0f, 88.0f));
    if (JumpButton)
    {
        JumpButton->OnPressed.AddDynamic(this, &UVICETouchHUD::OnJumpPressed);
        JumpButton->OnReleased.AddDynamic(this, &UVICETouchHUD::OnJumpReleased);
    }

    UButton* BrakeButton = AddActionButton(TEXT("刹车"), FVector2D(-238.0f, -112.0f), FVector2D(104.0f, 72.0f));
    if (BrakeButton)
    {
        BrakeButton->OnPressed.AddDynamic(this, &UVICETouchHUD::OnBrakePressed);
        BrakeButton->OnReleased.AddDynamic(this, &UVICETouchHUD::OnBrakeReleased);
    }

    UButton* SprintButton = AddActionButton(TEXT("奔跑"), FVector2D(-360.0f, -112.0f), FVector2D(104.0f, 72.0f));
    if (SprintButton)
    {
        SprintButton->OnPressed.AddDynamic(this, &UVICETouchHUD::OnSprintPressed);
        SprintButton->OnReleased.AddDynamic(this, &UVICETouchHUD::OnSprintReleased);
    }
}

UButton* UVICETouchHUD::AddActionButton(const FString& Label, const FVector2D& Position, const FVector2D& Size)
{
    UCanvasPanel* RootCanvas = Cast<UCanvasPanel>(WidgetTree ? WidgetTree->RootWidget : nullptr);
    if (!RootCanvas || !WidgetTree)
    {
        return nullptr;
    }

    UButton* Button = WidgetTree->ConstructWidget<UButton>(UButton::StaticClass());
    UTextBlock* Text = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass());
    Text->SetText(FText::FromString(Label));
    Text->SetJustification(ETextJustify::Center);
    Button->AddChild(Text);

    UCanvasPanelSlot* Slot = RootCanvas->AddChildToCanvas(Button);
    Slot->SetAnchors(FAnchors(1.0f, 1.0f, 1.0f, 1.0f));
    Slot->SetAlignment(FVector2D(1.0f, 1.0f));
    Slot->SetPosition(Position);
    Slot->SetSize(Size);
    return Button;
}

void UVICETouchHUD::OnCameraPressed()
{
    if (!ControlledCharacter)
    {
        return;
    }

    if (AVICEVehiclePawn* Vehicle = ControlledCharacter->GetCurrentVehicle())
    {
        Vehicle->ToggleCameraPerspective();
    }
    else
    {
        ControlledCharacter->ToggleCameraPerspective();
    }
}

void UVICETouchHUD::OnJumpPressed()
{
    if (ControlledCharacter && !ControlledCharacter->GetCurrentVehicle())
    {
        ControlledCharacter->Jump();
    }
}

void UVICETouchHUD::OnJumpReleased()
{
    if (ControlledCharacter && !ControlledCharacter->GetCurrentVehicle())
    {
        ControlledCharacter->StopJumping();
    }
}

void UVICETouchHUD::OnSprintPressed()
{
    if (ControlledCharacter && !ControlledCharacter->GetCurrentVehicle())
    {
        ControlledCharacter->StartSprint();
    }
}

void UVICETouchHUD::OnSprintReleased()
{
    if (ControlledCharacter && !ControlledCharacter->GetCurrentVehicle())
    {
        ControlledCharacter->StopSprint();
    }
}

void UVICETouchHUD::OnVehiclePressed()
{
    if (ControlledCharacter)
    {
        ControlledCharacter->InteractWithVehicle();
    }
}

void UVICETouchHUD::OnBrakePressed()
{
    if (ControlledCharacter)
    {
        if (AVICEVehiclePawn* Vehicle = ControlledCharacter->GetCurrentVehicle())
        {
            Vehicle->SetBrakeInput(true);
        }
    }
}

void UVICETouchHUD::OnBrakeReleased()
{
    if (ControlledCharacter)
    {
        if (AVICEVehiclePawn* Vehicle = ControlledCharacter->GetCurrentVehicle())
        {
            Vehicle->SetBrakeInput(false);
        }
    }
}

void UVICETouchHUD::NativeTick(const FGeometry& MyGeometry, float InDeltaTime)
{
    Super::NativeTick(MyGeometry, InDeltaTime);

    if (!SpeedReadout || !ControlledCharacter)
    {
        return;
    }

    if (const AVICEVehiclePawn* Vehicle = ControlledCharacter->GetCurrentVehicle())
    {
        SpeedReadout->SetText(FText::FromString(
            FString::Printf(TEXT("%03.0f km/h"), Vehicle->GetSpeedKmh())));
    }
    else
    {
        SpeedReadout->SetText(FText::FromString(TEXT("VICE CITY")));
    }
}
