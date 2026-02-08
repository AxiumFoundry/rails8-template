#!/bin/bash
LOG_FILE="$CLAUDE_PROJECT_DIR/.claude/hooks/hook_execution.log"
HOOK_NAME="$1"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

mkdir -p "$(dirname "$LOG_FILE")"

echo "[$TIMESTAMP] Hook: $HOOK_NAME - Started" >> "$LOG_FILE"

log_result() {
    local exit_code=$1
    local message="$2"
    echo "[$TIMESTAMP] Hook: $HOOK_NAME - Exit Code: $exit_code - $message" >> "$LOG_FILE"
    echo "----------------------------------------" >> "$LOG_FILE"
}

export -f log_result
export LOG_FILE HOOK_NAME TIMESTAMP
