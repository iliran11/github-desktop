#!/usr/bin/env bash
# Builds this fork and installs it to /Applications, then relaunches it.
# Uses the development channel so the app is ad-hoc signed locally and never
# auto-updates itself to an official GitHub Desktop release.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# The repo pins an exact Node (and the npm bundled with it) in .nvmrc; keep it
# in a private prefix so the system-wide Node stays untouched.
NODE_VERSION="$(tr -d 'v[:space:]' < .nvmrc)"
export N_PREFIX="$HOME/.cache/github-desktop-node"
if [ "$("$N_PREFIX/bin/node" -v 2>/dev/null)" != "v$NODE_VERSION" ]; then
  n install "$NODE_VERSION"
fi
export PATH="$N_PREFIX/bin:$PATH"

if [ ! -d node_modules ] || [ package-lock.json -nt node_modules ]; then
  npm ci
fi

# build:dev loads its UI from a webpack dev server, so it can't run standalone.
# A production bundle on the development channel is self-contained, ad-hoc
# signed, and has auto-update disabled.
RELEASE_CHANNEL=development npm run build:prod

APP_NAME="GitHub Desktop.app"
ARCH="$(uname -m)"
[ "$ARCH" = "x86_64" ] && ARCH="x64"
BUILT_APP="$REPO_ROOT/dist/GitHub Desktop-darwin-$ARCH/$APP_NAME"
INSTALLED_APP="/Applications/$APP_NAME"

osascript -e 'quit app "GitHub Desktop"' 2>/dev/null || true
sleep 1
rm -rf "$INSTALLED_APP"
ditto "$BUILT_APP" "$INSTALLED_APP"
open "$INSTALLED_APP"
