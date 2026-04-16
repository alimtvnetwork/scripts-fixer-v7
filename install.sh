#!/usr/bin/env bash
# --------------------------------------------------------------------------
#  Scripts Fixer -- One-liner bootstrap installer (Unix/macOS)
#  Usage:  curl -fsSL https://raw.githubusercontent.com/alimtvnetwork/scripts-fixer-v7/main/install.sh | bash
# --------------------------------------------------------------------------
set -e

REPO="https://github.com/alimtvnetwork/scripts-fixer-v7.git"
FOLDER="$HOME/scripts-fixer"

echo ""
echo "  Scripts Fixer -- Bootstrap Installer"
echo ""

# -- Check git is available ---------------------------------------------------
if ! command -v git &>/dev/null; then
    echo "  [ERROR] git is not installed. Install Git first, then re-run."
    echo "          https://git-scm.com/downloads"
    exit 1
fi

# -- Clone or pull ------------------------------------------------------------
if [ -d "$FOLDER/.git" ]; then
    echo "  [OK] Repo already exists at $FOLDER -- pulling latest..."
    git -C "$FOLDER" pull --ff-only >/dev/null 2>&1
else
    echo "  [>>] Cloning into $FOLDER ..."
    git clone "$REPO" "$FOLDER" >/dev/null 2>&1
    if [ ! -d "$FOLDER" ]; then
        echo "  [ERROR] Clone failed. Check your network and try again."
        exit 1
    fi
    echo "  [OK] Cloned successfully."
fi

echo ""
echo "  Done! To get started:"
echo "    cd $FOLDER"
echo "    pwsh ./run.ps1 -d"
echo ""
