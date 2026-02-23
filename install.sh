#!/usr/bin/env bash
set -euo pipefail
# ============================================================
# AudioTX Control — Installer
# ============================================================
# Downloads the latest (or specified) release and runs the
# installer. Hosted on GitHub Pages for a short URL.
#
# Install latest version:
#   curl -fsSL https://brianwynne.github.io/audiotxcontrol-install/install.sh \
#     | sudo bash -s -- --token github_pat_xxxxx
#
# Install specific version:
#   curl -fsSL https://brianwynne.github.io/audiotxcontrol-install/install.sh \
#     | sudo bash -s -- --tag v1.2.0 --token github_pat_xxxxx
#
# With GITHUB_TOKEN env var (no --token needed):
#   export GITHUB_TOKEN=github_pat_xxxxx
#   curl -fsSL https://brianwynne.github.io/audiotxcontrol-install/install.sh \
#     | sudo -E bash
# ============================================================

TAG=""
GH_TOKEN="${GITHUB_TOKEN:-}"
EXTRA_ARGS=()
REPO="brianwynne/audiotxcontrol"

while [[ $# -gt 0 ]]; do
    case $1 in
        --tag)    TAG="$2"; shift 2 ;;
        --token)  GH_TOKEN="$2"; shift 2 ;;
        *)        EXTRA_ARGS+=("$1"); shift ;;
    esac
done

[[ -n "$GH_TOKEN" ]] || { echo "ERROR: --token is required (or set GITHUB_TOKEN env var)"; exit 1; }

AUTH="Authorization: token $GH_TOKEN"
API="https://api.github.com/repos/$REPO"

# If no tag specified, fetch the latest release
if [[ -z "$TAG" ]]; then
    echo "[INFO] Fetching latest release..."
    TAG=$(curl -fsSL -H "$AUTH" "$API/releases/latest" \
        | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])") \
        || { echo "ERROR: Could not determine latest release. Use --tag to specify."; exit 1; }
    echo "[INFO] Latest release: $TAG"
fi

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  ARCH_LABEL="amd64" ;;
    aarch64) ARCH_LABEL="arm64" ;;
    *)       echo "ERROR: Unsupported architecture: $ARCH"; exit 1 ;;
esac

BUNDLE="audiotxcontrol_${ARCH_LABEL}_${TAG}.tar.gz"
echo "[INFO] Architecture: $ARCH ($ARCH_LABEL)"
echo "[INFO] Installing AudioTX Control $TAG..."

# Find the download URL for the bundle asset
RELEASE_JSON=$(curl -fsSL -H "$AUTH" "$API/releases/tags/$TAG") \
    || { echo "ERROR: Could not fetch release $TAG. Check tag and token."; exit 1; }

ASSET_URL=$(echo "$RELEASE_JSON" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for asset in data.get('assets', []):
    if asset['name'] == '$BUNDLE':
        print(asset['url'])
        break
else:
    sys.exit(1)
") || { echo "ERROR: $BUNDLE not found in release $TAG"; exit 1; }

# Download and extract
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

echo "[INFO] Downloading $BUNDLE..."
curl -fsSL -H "$AUTH" -H "Accept: application/octet-stream" -o "$TMPDIR/$BUNDLE" "$ASSET_URL" \
    || { echo "ERROR: Failed to download $BUNDLE"; exit 1; }

echo "[INFO] Extracting..."
mkdir -p "$TMPDIR/bundle"
tar -xzf "$TMPDIR/$BUNDLE" -C "$TMPDIR/bundle"

# Run the installer
echo "[INFO] Running installer..."
bash "$TMPDIR/bundle/install-audiotxcontrol.sh" "${EXTRA_ARGS[@]}"
