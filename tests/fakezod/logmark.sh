#!/usr/bin/env bash
# logmark.sh - print the current end of the ship log ($LOG) as a byte
# offset.  Pass it to logsince.sh to see only what was logged afterwards:
#   m=$(./logmark.sh); ./dojo.sh '|install our %hello'; ./logsince.sh -q 5 "$m"
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"
log_mark
