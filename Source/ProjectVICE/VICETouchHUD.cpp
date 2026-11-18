#include "VICETouchHUD.h"
#include "VICECharacter.h"
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

    UButton* CameraButton = AddActionButton(TEXT("视角"), FVector2D(-112.0f, -220.0f), FVector2D(96.0f, 64.0f));
    if (CameraButton)
    {
        CameraButton->OnClicked.AddDynamic(this, &UVICETouchHUD::OnCameraPressed);
    }

    UButton* JumpButton = AddActionButton(TEXT("跳跃"), FVector2D(-116.0f, -112.0f), FVector2D(104.0f, 88.0f));
    if (JumpButton)
    {
        JumpButton->OnPressed.AddDynamic(this, &UVICETouchHUD::OnJumpPressed);
        JumpButton->OnReleased.AddDynamic(this, &UVICETouchHUD::OnJumpReleased);
    }

    UButton* SprintButton = AddActionButton(TEXT("奔跑"), FVector2D(-238.0f, -88.0f), FVector2D(104.0f, 72.0f));
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
    if (ControlledCharacter)
    {
        ControlledCharacter->ToggleCameraPerspective();
    }
}

void UVICETouchHUD::OnJumpPressed()
{
    if (ControlledCharacter)
    {
        ControlledCharacter->Jump();
    }
}

void UVICETouchHUD::OnJumpReleased()
{
    if (ControlledCharacter)
    {
        ControlledCharacter->StopJumping();
    }
}

void UVICETouchHUD::OnSprintPressed()
{
    if (ControlledCharacter)
    {
        ControlledCharacter->StartSprint();
    }
}

void UVICETouchHUD::OnSprintReleased()
{
    if (ControlledCharacter)
    {
        ControlledCharacter->StopSprint();
    }
}
