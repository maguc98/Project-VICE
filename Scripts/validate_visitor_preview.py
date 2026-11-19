#!/usr/bin/env python3
"""Validate the repository wiring for the Project VICE visitor preview."""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    target = ROOT / path
    if not target.is_file():
        raise SystemExit(f"Missing visitor-preview file: {path}")
    return target.read_text(encoding="utf-8")


project = json.loads(read("ProjectVICE.uproject"))
engine_ini = read("Config/DefaultEngine.ini")
hud_cpp = read("Source/ProjectVICE/VICETouchHUD.cpp")
hud_header = read("Source/ProjectVICE/VICETouchHUD.h")
map_script = read("Content/Python/create_vice_blockout_map.py")
package_script = read("Scripts/package_ios_preview.sh")
workflow = read(".github/workflows/ios-visitor-preview.yml")
readme = read("README.md")
preview_docs = read("Docs/IOS_VISITOR_PREVIEW.md")

if project.get("EngineAssociation") != "5.4":
    raise SystemExit("Visitor preview must remain pinned to Unreal Engine 5.4.")
if "IOS" not in project.get("TargetPlatforms", []):
    raise SystemExit("iOS is not listed as a target platform.")

required_engine_settings = (
    "GameDefaultMap=/Game/Maps/L_ViceCity_Blockout.L_ViceCity_Blockout",
    "EditorStartupMap=/Engine/Maps/Entry",
    "ProjectVersion=0.1.0",
    "ProjectName=Project VICE - Visitor Preview",
    "BundleIdentifier=com.maguc98.projectvice",
    "BundleName=ProjectVICE",
    "BundleDisplayName=Project VICE",
    "bAutomaticSigning=False",
    "IOSTeamID=",
    "MobileProvision=",
    "SigningCertificate=",
    "MinimumiOSVersion=IOS_15",
)
for setting in required_engine_settings:
    if setting not in engine_ini:
        raise SystemExit(f"Missing visitor-preview setting: {setting}")

if 'MAP_PATH = "/Game/Maps/L_ViceCity_Blockout"' not in map_script:
    raise SystemExit("Map bootstrap path does not match GameDefaultMap.")
if "build_vice_city_blockout()" not in map_script:
    raise SystemExit("Map bootstrap script no longer creates the preview map.")

for widget_name in ("PreviewHeader", "PreviewHint", "SpeedReadout"):
    if widget_name not in hud_header or widget_name not in hud_cpp:
        raise SystemExit(f"Visitor preview HUD widget is incomplete: {widget_name}")
for label in ("游客预览版", "左侧摇杆移动", "步行探索  ·  游客模式"):
    if label not in hud_cpp:
        raise SystemExit(f"Missing visitor-preview HUD copy: {label}")

for token in (
    "UnrealEditor-Cmd",
    "-ExecutePythonScript=",
    "BuildCookRun",
    "-platform=IOS",
    "-clientconfig=Development",
    "-build -cook -stage -pak -package -archive",
    "security find-identity",
    "Provisioning profile verified",
    "ProjectVICE-VisitorPreview.ipa",
):
    if token not in package_script:
        raise SystemExit(f"iOS packaging script is missing: {token}")

if "self-hosted, macOS, ue5.4, ios" not in workflow:
    raise SystemExit("iOS preview workflow must target a macOS UE 5.4 self-hosted runner.")
if "actions/upload-artifact@v4" not in workflow:
    raise SystemExit("iOS preview workflow must publish the IPA artifact.")
if "游客预览版" not in readme or "iOS visitor preview" not in preview_docs:
    raise SystemExit("Visitor-preview documentation is incomplete.")

print(
    "Visitor preview wiring passed: UE 5.4 project config, generated map path, "
    "guest HUD, local signing checks, iOS package script, and artifact workflow."
)
