#!/usr/bin/env bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

REPO="ruivalim/gitignore-cli" 
INSTALL_DIR="$HOME/.local/bin"
BINARY_NAME="gitignore"

while [[ $# -gt 0 ]]; do
    case $1 in
        --prefix=*)
            INSTALL_DIR="${1#*=}"
            shift
            ;;
        --prefix)
            INSTALL_DIR="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: curl -sSL https://raw.githubusercontent.com/$REPO/main/install.sh | bash"
            echo "   or: curl -sSL https://raw.githubusercontent.com/$REPO/main/install.sh | bash -s -- --prefix=/usr/local/bin"
            echo ""
            echo "Options:"
            echo "  --prefix=DIR    Install to DIR (default: $HOME/.local/bin)"
            echo "  --help         Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}Gitignore CLI Installer${NC}"
echo -e "${BLUE}======================${NC}"
echo ""

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case $ARCH in
    x86_64)
        ARCH="x86_64"
        ;;
    arm64|aarch64)
        ARCH="aarch64"
        ;;
    *)
        echo -e "${RED}Unsupported architecture: $ARCH${NC}"
        exit 1
        ;;
esac

case $OS in
    linux)
        PLATFORM="unknown-linux-gnu"
        ;;
    darwin)
        PLATFORM="apple-darwin"
        ;;
    *)
        echo -e "${RED}Unsupported OS: $OS${NC}"
        exit 1
        ;;
esac

TARGET="$ARCH-$PLATFORM"
echo -e "${YELLOW}Detected platform: $TARGET${NC}"

for cmd in curl tar; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}Error: $cmd is required but not installed.${NC}"
        exit 1
    fi
done

echo -e "${YELLOW}Fetching latest release info...${NC}"
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/$REPO/releases/latest")

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to fetch release information from GitHub.${NC}"
    echo "Please check if the repository exists and is public: https://github.com/$REPO"
    exit 1
fi

TAG_NAME=$(echo "$LATEST_RELEASE" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
if [ -z "$TAG_NAME" ]; then
    echo -e "${RED}Error: Could not parse release tag from GitHub API response.${NC}"
    exit 1
fi

echo -e "${GREEN}Latest version: $TAG_NAME${NC}"

DOWNLOAD_URL="https://github.com/$REPO/releases/download/$TAG_NAME/$BINARY_NAME-$TAG_NAME-$TARGET.tar.gz"

echo -e "${YELLOW}Download URL: $DOWNLOAD_URL${NC}"

TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

echo -e "${YELLOW}Downloading $BINARY_NAME $TAG_NAME...${NC}"
if ! curl -L --fail "$DOWNLOAD_URL" -o "$TMP_DIR/$BINARY_NAME.tar.gz"; then
    echo -e "${RED}Error: Failed to download release.${NC}"
    echo "URL: $DOWNLOAD_URL"
    echo ""
    echo "This might mean:"
    echo "1. No release has been published yet"
    echo "2. The release doesn't include binaries for your platform ($TARGET)"
    echo "3. The repository name is incorrect"
    echo ""
    echo "Try building from source instead:"
    echo "  git clone https://github.com/$REPO.git"
    echo "  cd gitignore-cli"
    echo "  cargo install --path ."
    exit 1
fi

echo -e "${YELLOW}Extracting...${NC}"
tar -xzf "$TMP_DIR/$BINARY_NAME.tar.gz" -C "$TMP_DIR"

mkdir -p "$INSTALL_DIR"

echo -e "${YELLOW}Installing to $INSTALL_DIR...${NC}"
cp "$TMP_DIR/$BINARY_NAME" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/$BINARY_NAME"

echo -e "${GREEN}✓ Installation complete!${NC}"
echo ""
echo "The '$BINARY_NAME' command has been installed to: $INSTALL_DIR/$BINARY_NAME"
echo ""

if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo -e "${YELLOW}Note: $INSTALL_DIR is not in your PATH.${NC}"
    echo "Add this line to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
    echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
    echo ""
    echo "Or run the command with the full path:"
    echo "  $INSTALL_DIR/$BINARY_NAME --help"
else
    echo "You can now use: $BINARY_NAME --help"
fi

echo ""
echo "Examples:"
echo "  $BINARY_NAME Python      # Download Python .gitignore"
echo "  $BINARY_NAME ls          # List available templates"
echo "  $BINARY_NAME             # Interactive mode (requires fzf)"
