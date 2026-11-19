# iOS visitor preview build

## Scope

The visitor preview is a direct-to-game guest experience: it does not require an account or sign-in. On launch, the player enters the coastal-city graybox and can walk, jump, sprint, switch camera perspective, and enter/drive/exit the prototype sedan. The HUD identifies the build as **Project VICE — 游客预览版**. The left virtual stick controls walking or vehicle throttle/steering, the right stick controls camera look, and on-screen actions handle jump, sprint, brake, camera, and vehicle enter/exit. The generated map includes SkyAtmosphere; the runtime day/night controller owns movable directional-sun and skylight components and links the sun to the atmosphere.

This is an engineering preview, not a public release candidate. The city, character, vehicle, pedestrians, traffic, and waterfront are still graybox prototypes.

## Required build machine

An iOS package (unsigned for later signing, or signed on the build machine) must be built on macOS with:

- Unreal Engine **5.4**, including its iOS platform support and Automation Tool.
- An Xcode version supported by that UE 5.4 installation, plus Xcode command-line tools.
- For **unsigned** builds: no Apple signing identity or provisioning profile is required at build time.
- For **signed** builds: an Apple development signing identity and matching iOS Development or Ad Hoc profile for `com.maguc98.projectvice` are required.

An unsigned IPA is a packaging artifact, not directly installable until it is signed with a matching certificate and provisioning profile. Keep private `.p12` files and profiles off the repository.

## Local macOS build

For an unsigned package (the default), only set the Unreal installation path:

```bash
export UE_ROOT="/path/to/UnrealEngine_5.4"
export IOS_SIGNING_MODE=unsigned
bash Scripts/package_ios_preview.sh
```

For a signed package, install the certificate and profile locally, then set `IOS_SIGNING_MODE=signed` plus `IOS_TEAM_ID`, `IOS_SIGNING_CERTIFICATE`, and `IOS_MOBILE_PROVISION`.

The script:

1. Confirms macOS, Xcode, and Unreal Engine 5.4 tools. Signed mode additionally validates the local identity and profile.
2. Signed mode temporarily injects local signing settings and restores the original config on exit; unsigned mode leaves project signing settings untouched.
3. Opens Unreal Editor in command-line mode and runs `Content/Python/create_vice_blockout_map.py` to generate the currently missing `Content/Maps/L_ViceCity_Blockout.umap`.
4. Runs Unreal Automation Tool `BuildCookRun` for iOS Development, including build, cook, stage, package, and archive.
5. Copies the resulting IPA to `Artifacts/IOS/ProjectVICE-VisitorPreview.ipa` and writes a SHA-256 checksum.

The generated map and package artifacts are local build outputs; they are not committed to source control.

## GitHub Actions build

The repository contains a manually triggered workflow:

`.github/workflows/ios-visitor-preview.yml`

It requires a **self-hosted macOS runner** with these labels:

`self-hosted`, `macOS`, `ue5.4`, `ios`

The runner must have UE 5.4 and Xcode installed. Select `unsigned` in the workflow input to build without Apple signing assets; select `signed` only when the runner has a matching identity and provisioning profile. `UE_ROOT` is the only required repository variable for unsigned builds. Configure these repository Actions Variables for signed builds:

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
- [x] Local packaging script supports unsigned and signed modes.
- [x] Manual GitHub Actions workflow exposes unsigned and signed build modes.
- [ ] Run UE 5.4 Header Tool and C++ compilation.
- [ ] Cook and package on a configured macOS runner (unsigned mode does not require signing assets).
- [ ] Install and launch on the target iPhone.
- [ ] Complete a representative play session and fix any crashes, touch-layout issues, or streaming hitches.

GitHub's Linux source-validation workflow does **not** compile Unreal C++ and is not evidence that an IPA has been produced. Until the macOS build and device gates above pass, the preview is source-ready only, not an installable IPA.
