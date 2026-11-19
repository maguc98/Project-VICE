# iOS visitor preview build

## Scope

The visitor preview is a direct-to-game guest experience: it does not require an account or sign-in. On launch, the player enters the coastal-city graybox and can walk, jump, sprint, switch camera perspective, and enter/drive/exit the prototype sedan. The HUD identifies the build as **Project VICE — 游客预览版**. The left virtual stick controls walking or vehicle throttle/steering, the right stick controls camera look, and on-screen actions handle jump, sprint, brake, camera, and vehicle enter/exit. The generated map includes a SkyAtmosphere linked to the directional sun.

This is an engineering preview, not a public release candidate. The city, character, vehicle, pedestrians, traffic, and waterfront are still graybox prototypes.

## Required build machine

A signed iOS package must be built on macOS with:

- Unreal Engine **5.4**, including its iOS platform support and Automation Tool.
- An Xcode version supported by that UE 5.4 installation, plus Xcode command-line tools.
- An Apple development signing identity installed in the macOS keychain.
- A matching iOS Development or Ad Hoc provisioning profile for bundle ID `com.maguc98.projectvice`.
- The target iPhone registered in the provisioning profile when using a device-limited Development/Ad Hoc profile.

The signing identity and profile must belong to the same Apple team and match the bundle identifier. The private `.p12` and provisioning profile should stay on the build machine; do not commit them to this repository or paste them into chat.

## Local macOS build

Install the signing certificate into the current user's keychain and place the provisioning profile in:

`~/Library/MobileDevice/Provisioning Profiles/`

Then run from the repository root:

```bash
export UE_ROOT="/path/to/UnrealEngine_5.4"
export IOS_TEAM_ID="YOUR10CHARTEAM"
export IOS_SIGNING_CERTIFICATE="Apple Development: Your Name (YOUR10CHARTEAM)"
export IOS_MOBILE_PROVISION="ProjectVICE-Visitor.mobileprovision"
bash Scripts/package_ios_preview.sh
```

The script:

1. Confirms macOS, Xcode, Unreal Engine 5.4 tools, signing identity, and provisioning-profile team/App ID.
2. Temporarily injects the local signing identity into `Config/DefaultEngine.ini` and restores the original file on exit.
3. Opens Unreal Editor in command-line mode and runs `Content/Python/create_vice_blockout_map.py` to generate the currently missing `Content/Maps/L_ViceCity_Blockout.umap`.
4. Runs Unreal Automation Tool `BuildCookRun` for iOS Development, including build, cook, stage, package, and archive.
5. Copies the resulting IPA to `Artifacts/IOS/ProjectVICE-VisitorPreview.ipa` and writes a SHA-256 checksum.

The generated map and package artifacts are local build outputs; they are not committed to source control.

## GitHub Actions build

The repository contains a manually triggered workflow:

`.github/workflows/ios-visitor-preview.yml`

It requires a **self-hosted macOS runner** with these labels:

`self-hosted`, `macOS`, `ue5.4`, `ios`

The runner must have UE 5.4 and Xcode installed, and its local keychain and provisioning-profile directory must already contain the signing assets. Configure these repository Actions Variables:

| Variable | Value |
|---|---|
| `UE_ROOT` | Absolute path to the UE 5.4 installation |
| `IOS_TEAM_ID` | Apple Developer Team ID |
| `IOS_SIGNING_CERTIFICATE` | Exact signing identity shown by `security find-identity -v -p codesigning` |
| `IOS_MOBILE_PROVISION` | Provisioning profile filename in the user's MobileDevice directory |

No private signing key is uploaded to GitHub by this workflow. Once the runner and variables are configured, open **Actions → iOS Visitor Preview → Run workflow**. A successful run publishes `ProjectVICE-VisitorPreview.ipa` as the `ProjectVICE-VisitorPreview-iOS` artifact.

## Current gate status

- [x] Guest flow has no login requirement.
- [x] Visitor-preview identity and touch hints are included in the runtime HUD.
- [x] UE editor bootstrap script creates the map referenced by the game default map.
- [x] Local signed iOS packaging script is in the repository.
- [x] Manual GitHub Actions workflow and artifact upload are defined.
- [ ] Run UE 5.4 Header Tool and C++ compilation.
- [ ] Cook and package on a configured macOS runner with the project's real signing assets.
- [ ] Install and launch on the target iPhone.
- [ ] Complete a representative play session and fix any crashes, touch-layout issues, or streaming hitches.

GitHub's Linux source-validation workflow does **not** compile Unreal C++ and is not evidence that an IPA has been produced. Until the macOS build and device gates above pass, the preview is source-ready only, not an installable IPA.
