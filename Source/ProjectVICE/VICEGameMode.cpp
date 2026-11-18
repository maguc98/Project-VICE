#include "VICEGameMode.h"
#include "VICECharacter.h"

AVICEGameMode::AVICEGameMode()
{
    DefaultPawnClass = AVICECharacter::StaticClass();
}
