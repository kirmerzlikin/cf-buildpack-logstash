#!/bin/bash
set -euo pipefail # Enable bash strict mode (http://redsymbol.net/articles/unofficial-bash-strict-mode/)
if [[ ${DEBUG:-0} -eq 1 ]]; then
	set -x # DEBUG
	exec 3>&1
else
	exec 3>/dev/null
fi

steptxt="----->"
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m' # No Color
CURL="/usr/bin/curl -s -L --retry 15 --retry-delay 2" # retry for up to 30 seconds

warn() {
    echo -e "${YELLOW} !!    $@${NC}"
}

err() {
    echo -e >&2 "${RED} !!    $@${NC}"
    exit 1
}

step() {
    echo "$steptxt $@"
}

start() {
    echo -n "$steptxt $@... "
}

finished() {
    echo "done"
}

indent() {
  sed -u 's/^/       /' >&3
}