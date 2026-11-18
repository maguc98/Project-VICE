using UnrealBuildTool;

public class ProjectVICEEditorTarget : TargetRules
{
    public ProjectVICEEditorTarget(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Editor;
        DefaultBuildSettings = BuildSettingsVersion.V5;
        ExtraModuleNames.Add("ProjectVICE");
    }
}
