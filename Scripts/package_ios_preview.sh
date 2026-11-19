#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT/ProjectVICE.uproject"
MAP_SCRIPT="$ROOT/Content/Python/create_vice_blockout_map.py"
MAP_FILE="$ROOT/Content/Maps/L_ViceCity_Blockout.umap"
ARCHIVE_DIR="$ROOT/Artifacts/IOS/VisitorPreviewArchive"
OUTPUT_DIR="$ROOT/Artifacts/IOS"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

[[ "$(uname -s)" == "Darwin" ]] || fail "iOS packaging must run on macOS with Xcode installed."
[[ -f "$PROJECT" ]] || fail "ProjectVICE.uproject was not found."
[[ -f "$MAP_SCRIPT" ]] || fail "The Unreal Editor map bootstrap script is missing."

: "${UE_ROOT:?Set UE_ROOT to the Unreal Engine 5.4 installation directory.}"
IOS_SIGNING_MODE="${IOS_SIGNING_MODE:-unsigned}"
if [[ "$IOS_SIGNING_MODE" != "unsigned" && "$IOS_SIGNING_MODE" != "signed" ]]; then
  fail "IOS_SIGNING_MODE must be unsigned or signed."
fi
if [[ "$IOS_SIGNING_MODE" == "signed" ]]; then
  : "${IOS_TEAM_ID:?Set IOS_TEAM_ID to the Apple Developer Team ID.}"
  : "${IOS_SIGNING_CERTIFICATE:?Set IOS_SIGNING_CERTIFICATE to the exact installed codesigning identity name.}"
  : "${IOS_MOBILE_PROVISION:?Set IOS_MOBILE_PROVISION to the installed .mobileprovision filename or full path.}"
fi

EDITOR_CMD="$UE_ROOT/Engine/Binaries/Mac/UnrealEditor-Cmd"
RUN_UAT="$UE_ROOT/Engine/Build/BatchFiles/RunUAT.sh"
[[ -x "$EDITOR_CMD" ]] || fail "UnrealEditor-Cmd not found: $EDITOR_CMD"
[[ -x "$RUN_UAT" ]] || fail "RunUAT.sh not found: $RUN_UAT"
command -v xcodebuild >/dev/null 2>&1 || fail "Xcode command-line tools are unavailable."
xcodebuild -version

PROFILE_NAME=""
if [[ "$IOS_SIGNING_MODE" == "signed" ]]; then
  PROFILE_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"
  if [[ "$IOS_MOBILE_PROVISION" == /* ]]; then
    PROFILE_FILE="$IOS_MOBILE_PROVISION"
  else
    PROFILE_FILE="$PROFILE_DIR/$IOS_MOBILE_PROVISION"
  fi
  [[ -f "$PROFILE_FILE" ]] || fail "Provisioning profile not found: $PROFILE_FILE"
  
  # UE discovers profiles from this directory. Copy an explicitly supplied
  # external profile into it while retaining its original filename.
  mkdir -p "$PROFILE_DIR"
  PROFILE_NAME="$(basename "$PROFILE_FILE")"
  INSTALLED_PROFILE="$PROFILE_DIR/$PROFILE_NAME"
  if [[ "$PROFILE_FILE" != "$INSTALLED_PROFILE" ]]; then
    cp "$PROFILE_FILE" "$INSTALLED_PROFILE"
    PROFILE_FILE="$INSTALLED_PROFILE"
  fi
  
  IDENTITIES="$(security find-identity -v -p codesigning 2>/dev/null || true)"
  grep -F -- "$IOS_SIGNING_CERTIFICATE" <<< "$IDENTITIES" >/dev/null \
    || fail "The requested signing identity is not installed in the current macOS keychain."
  
  PROFILE_PLIST="$(mktemp)"
  CONFIG_BACKUP="$(mktemp)"
  cleanup() {
    rm -f "$PROFILE_PLIST"
    if [[ -f "$CONFIG_BACKUP" ]]; then
      cp "$CONFIG_BACKUP" "$ROOT/Config/DefaultEngine.ini"
      rm -f "$CONFIG_BACKUP"
    fi
  }
  cp "$ROOT/Config/DefaultEngine.ini" "$CONFIG_BACKUP"
  trap cleanup EXIT
  
  security cms -D -i "$PROFILE_FILE" > "$PROFILE_PLIST"
  BUNDLE_ID="${IOS_BUNDLE_IDENTIFIER:-com.maguc98.projectvice}"
  python3 - "$PROFILE_PLIST" "$IOS_TEAM_ID" "$BUNDLE_ID" <<'PY'
  import plistlib
  import sys
  
  profile_path, expected_team, bundle_id = sys.argv[1:]
  with open(profile_path, "rb") as stream:
      profile = plistlib.load(stream)
  
  teams = profile.get("TeamIdentifier", [])
  entitlements = profile.get("Entitlements", {})
  app_identifier = entitlements.get("application-identifier", "")
  if expected_team not in teams:
      raise SystemExit(f"Provisioning profile team mismatch: expected {expected_team}, got {teams}")
  expected_app_id = f"{expected_team}.{bundle_id}"
  if app_identifier not in (expected_app_id, f"{expected_team}.*"):
      raise SystemExit(
          f"Provisioning profile App ID mismatch: expected {expected_app_id}, got {app_identifier}"
      )
  if profile.get("ExpirationDate") is not None:
      from datetime import datetime, timezone
      expiry = profile["ExpirationDate"]
      if expiry.replace(tzinfo=timezone.utc) < datetime.now(timezone.utc):
          raise SystemExit(f"Provisioning profile expired: {expiry.isoformat()}")
  print(f"Provisioning profile verified for {bundle_id} ({expected_team}).")
  PY
  
  
fi

# The map asset is generated locally by the UE editor script before cooking.
mkdir -p "$ROOT/Saved/Logs" "$ARCHIVE_DIR" "$OUTPUT_DIR"
"$EDITOR_CMD" "$PROJECT" \
  -unattended -nop4 -nosplash -NullRHI \
  "-ExecutePythonScript=$MAP_SCRIPT" \
  "-log=$ROOT/Saved/Logs/VisitorPreviewMapGeneration.log"

[[ -f "$MAP_FILE" ]] || fail "The editor script did not create $MAP_FILE"

# Supply signing details only for signed builds; unsigned builds leave project config untouched.
if [[ "$IOS_SIGNING_MODE" == "signed" ]]; then
  python3 - "$ROOT/Config/DefaultEngine.ini" "$IOS_TEAM_ID" "$BUNDLE_ID" "$IOS_SIGNING_CERTIFICATE" "$(basename "$PROFILE_FILE")" <<'PY'
  import sys
  
  path, team, bundle, certificate, provision = sys.argv[1:]
  section_name = "[/Script/IOSRuntimeSettings.IOSRuntimeSettings]"
  updates = {
      "BundleIdentifier": bundle,
      "BundleName": "ProjectVICE",
      "BundleDisplayName": "Project VICE",
      "bAutomaticSigning": "False",
      "IOSTeamID": team,
      "MobileProvision": provision,
      "SigningCertificate": certificate,
  }
  with open(path, "r", encoding="utf-8") as stream:
      lines = stream.read().splitlines()
  
  if section_name not in lines:
      raise SystemExit("Missing IOSRuntimeSettings section in DefaultEngine.ini")
  
  start = lines.index(section_name)
  end = next((i for i in range(start + 1, len(lines)) if lines[i].startswith("[")), len(lines))
  seen = set()
  for index in range(start + 1, end):
      key = lines[index].split("=", 1)[0] if "=" in lines[index] else ""
      if key in updates:
          lines[index] = f"{key}={updates[key]}"
          seen.add(key)
  for key, value in updates.items():
      if key not in seen:
          lines.insert(end, f"{key}={value}")
          end += 1
  
  with open(path, "w", encoding="utf-8") as stream:
      stream.write("\n".join(lines) + "\n")
  PY
  
  
fi

UAT_SIGNING_ARGS=()
if [[ "$IOS_SIGNING_MODE" == "unsigned" ]]; then
  UAT_SIGNING_ARGS+=( -CodeSignIdentity= -Provision= )
fi

"$RUN_UAT" BuildCookRun \
  "-project=$PROJECT" \
  -noP4 -platform=IOS -clientconfig=Development \
  -build -cook -stage -pak -package -archive \
  "-archivedirectory=$ARCHIVE_DIR" \
  "${UAT_SIGNING_ARGS[@]}" \
  -utf8output -unattended

IPA_SOURCE="$(find "$ARCHIVE_DIR" -type f -name '*.ipa' -print -quit)"
[[ -n "$IPA_SOURCE" ]] || fail "Unreal completed without producing an .ipa. Inspect Saved/Logs and the UAT output above."

IPA_OUTPUT="$OUTPUT_DIR/ProjectVICE-VisitorPreview.ipa"
cp "$IPA_SOURCE" "$IPA_OUTPUT"
shasum -a 256 "$IPA_OUTPUT" | tee "$IPA_OUTPUT.sha256"
echo "Visitor preview IPA ($IOS_SIGNING_MODE): $IPA_OUTPUT"
