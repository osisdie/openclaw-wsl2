#!/usr/bin/env bash
# Legacy wrapper — delegates to start_gateway.sh
exec "$(dirname "$0")/start_gateway.sh" "$@"
