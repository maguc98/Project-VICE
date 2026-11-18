using UnrealBuildTool;
using System.Collections.Generic;

public class ProjectVICTarget : TargetRules
{
    public ProjectVICTarget(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Game;
        DefaultBuildSettings = BuildSettingsVersion.V5;
        ExtraModuleNames.Add("ProjectVICE");
    }
}
