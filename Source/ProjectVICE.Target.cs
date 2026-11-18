using UnrealBuildTool;

public class ProjectVICETarget : TargetRules
{
    public ProjectVICETarget(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Game;
        DefaultBuildSettings = BuildSettingsVersion.V5;
        ExtraModuleNames.Add("ProjectVICE");
    }
}
