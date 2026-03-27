#!/bin/sh

# Load local configuration.
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ENV_FILE="$SCRIPT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
    printf 'Missing .env file at %s\n' "$ENV_FILE" >&2
    exit 1
fi

set -a
. "$ENV_FILE"
set +a

: "${BORG_REPO:?BORG_REPO must be set in .env}"
: "${OP_REFERENCE_PASSWORD:?OP_REFERENCE_PASSWORD must be set in .env}"
: "${ICLOUD_BACKUP_DIRS:?ICLOUD_BACKUP_DIRS must be set in .env}"

if [ -z "${ICLOUD_DRIVE_ROOT:-}" ]; then
    ICLOUD_DRIVE_ROOT="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
fi

# Secrets
# ---------------------------------------------------------------

# Read passphrase from 1Password
export BORG_PASSPHRASE=$(op read "$OP_REFERENCE_PASSWORD")

# Utilities
# ---------------------------------------------------------------
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

require_command() {
    if ! command_exists "$1"; then
        printf 'Missing required command: %s\n' "$1" >&2
        exit 1
    fi
}

colorOutput() {
    color="$1"
    content="$2"

    default='\033[0m'
    red='\033[31m'
    green='\033[0;32m'
    yellow='\033[0;33m'
    cyan='\033[0;35m'
    magenta='\033[0;36m'

    case "$color" in
        default) color_code=$default ;;
        red) color_code=$red ;;
        green) color_code=$green ;;
        yellow) color_code=$yellow ;;
        cyan) color_code=$cyan ;;
        magenta) color_code=$magenta ;;
        *) color_code=$default ;;
    esac

    printf '%b%s%b\n' "$color_code" "$content" "$default"
}

printDefault () {
    colorOutput "default" "$1"
}

printInfo() {
    colorOutput "cyan" "$1"
}

printError() {
    colorOutput "red" "$1" >&2
}
