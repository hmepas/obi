#!/usr/bin/env bash
# Build release, install the binary to ~/.local/bin atomically and (re)start the launchd agent.
# The binary must be replaced via rename: overwriting the inode of a running/cached executable
# makes the kernel SIGKILL every new launch (code-signing page invalidation).
set -euo pipefail
cd "$(dirname "$0")/.."
DEST="${1:-$HOME/.local/bin/obi}"
/usr/bin/swift build -c release 2>&1 | grep -E "error|Build complete"
cp .build/release/obi "$DEST.new"
mv -f "$DEST.new" "$DEST"
"$DEST" install
