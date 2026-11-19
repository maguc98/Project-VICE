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

    // Visitor-preview identity is always visible; the game intentionally
    // starts directly in a guest session and does not require an account.
    PreviewHeader = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("PreviewHeader"));
    PreviewHeader->SetText(FText::FromString(TEXT("PROJECT VICE  /  游客预览版")));
    PreviewHeader->SetJustification(ETextJustify::Left);
    UCanvasPanelSlot* HeaderSlot = RootCanvas->AddChildToCanvas(PreviewHeader);
    HeaderSlot->SetAnchors(FAnchors(0.0f, 0.0f, 0.0f, 0.0f));
    HeaderSlot->SetAlignment(FVector2D(0.0f, 0.0f));
    HeaderSlot->SetPosition(FVector2D(28.0f, 22.0f));
    HeaderSlot->SetSize(FVector2D(320.0f, 32.0f));

    PreviewHint = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("PreviewHint"));
    PreviewHint->SetText(FText::FromString(TEXT("左侧摇杆移动  ·  右侧滑动转向  ·  靠近车辆后点击上车")));
    PreviewHint->SetJustification(ETextJustify::Left);
    UCanvasPanelSlot* HintSlot = RootCanvas->AddChildToCanvas(PreviewHint);
    HintSlot->SetAnchors(FAnchors(0.0f, 0.0f, 0.0f, 0.0f));
    HintSlot->SetAlignment(FVector2D(0.0f, 0.0f));
    HintSlot->SetPosition(FVector2D(28.0f, 54.0f));
    HintSlot->SetSize(FVector2D(420.0f, 30.0f));

    SpeedReadout = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("SpeedReadout"));
    SpeedReadout->SetText(FText::FromString(TEXT("步行探索")));
    SpeedReadout->SetJustification(ETextJustify::Left);
    UCanvasPanelSlot* SpeedSlot = RootCanvas->AddChildToCanvas(SpeedReadout);
    SpeedSlot->SetAnchors(FAnchors(0.0f, 0.0f, 0.0f, 0.0f));
    SpeedSlot->SetAlignment(FVector2D(0.0f, 0.0f));
    SpeedSlot->SetPosition(FVector2D(28.0f, 86.0f));
    SpeedSlot->SetSize(FVector2D(210.0f, 36.0f));

    UButton* CameraButton = AddActionButton(TEXT("视角"), FVector2D(-16.0f, 24.0f), FVector2D(92.0f, 56.0f));
    if (CameraButton)
    {
        CameraButton->OnClicked.AddDynamic(this, &UVICETouchHUD::OnCameraPressed);
    }

    UButton* VehicleButton = AddActionButton(TEXT("上车 / 下车"), FVector2D(-118.0f, 24.0f), FVector2D(100.0f, 56.0f));
    if (VehicleButton)
    {
        VehicleButton->OnClicked.AddDynamic(this, &UVICETouchHUD::OnVehiclePressed);
    }

    UButton* JumpButton = AddActionButton(TEXT("跳跃"), FVector2D(-16.0f, 88.0f), FVector2D(92.0f, 56.0f));
    if (JumpButton)
    {
        JumpButton->OnPressed.AddDynamic(this, &UVICETouchHUD::OnJumpPressed);
        JumpButton->OnReleased.AddDynamic(this, &UVICETouchHUD::OnJumpReleased);
    }

    UButton* BrakeButton = AddActionButton(TEXT("刹车"), FVector2D(-118.0f, 88.0f), FVector2D(100.0f, 56.0f));
    if (BrakeButton)
    {
        BrakeButton->OnPressed.AddDynamic(this, &UVICETouchHUD::OnBrakePressed);
        BrakeButton->OnReleased.AddDynamic(this, &UVICETouchHUD::OnBrakeReleased);
    }

    UButton* SprintButton = AddActionButton(TEXT("奔跑"), FVector2D(-16.0f, 152.0f), FVector2D(92.0f, 56.0f));
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
    Slot->SetAnchors(FAnchors(1.0f, 0.0f, 1.0f, 0.0f));
    Slot->SetAlignment(FVector2D(1.0f, 0.0f));
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
        SpeedReadout->SetText(FText::FromString(TEXT("步行探索  ·  游客模式")));
    }
}
