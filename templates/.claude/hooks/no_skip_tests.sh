#!/bin/bash
source "$CLAUDE_PROJECT_DIR/.claude/hooks/log_hook.sh" "no_skip_tests"

if [[ "$@" == *"--no-verify"* ]]; then
  echo "BLOCKED: Never use --no-verify to bypass tests!"
  echo "All tests must pass before committing."
  echo "Fix any failing tests, even if they seem unrelated to your changes."
  exit 1
fi

log_result 0 "Check completed successfully"
exit 0
