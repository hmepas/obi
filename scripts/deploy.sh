#!/usr/bin/env bash
# Build release, install obi.app to ~/Applications and (re)start the launchd agent.
# bundle.sh recreates the bundle from scratch: overwriting the inode of a running/cached
# executable makes the kernel SIGKILL every new launch (code-signing page invalidation).
set -euo pipefail
cd "$(dirname "$0")/.."
DEST="${1:-$HOME/Applications/obi.app}"
/usr/bin/swift build -c release 2>&1 | grep -E "error|Build complete"
mkdir -p "$(dirname "$DEST")"
scripts/bundle.sh .build/release/obi "$DEST"
"$DEST/Contents/MacOS/obi" install
