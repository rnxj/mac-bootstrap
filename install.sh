#!/usr/bin/env bash
set -euo pipefail

# mac-bootstrap installer
# Usage: curl -fsSL https://raw.githubusercontent.com/rnxj/mac-bootstrap/main/install.sh | bash

REPO="rnxj/mac-bootstrap"
BRANCH="main"
INSTALL_DIR="$HOME/.mac-bootstrap"

echo "🚀 mac-bootstrap installer"

# Download and extract
echo "📥 Downloading..."
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
curl -fsSL "https://github.com/$REPO/archive/$BRANCH.tar.gz" | tar -xz --strip-components=1 -C "$INSTALL_DIR"

# Run bootstrap
echo ""
cd "$INSTALL_DIR"
./bootstrap.sh

echo ""
echo "📁 Bootstrap files installed to: $INSTALL_DIR"
echo "   You can re-run anytime with: ~/.mac-bootstrap/bootstrap.sh"
