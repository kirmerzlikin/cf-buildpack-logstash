#!/bin/bash
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
