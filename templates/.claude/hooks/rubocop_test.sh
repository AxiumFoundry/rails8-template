#!/bin/bash
source "$CLAUDE_PROJECT_DIR/.claude/hooks/log_hook.sh" "rubocop_test"
cd "$CLAUDE_PROJECT_DIR"

STDIN_DATA=$(cat)
FILE_PATH=$(echo "$STDIN_DATA" | grep -o '"file_path":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$FILE_PATH" ]; then
    FILE_PATH=$(echo "$STDIN_DATA" | grep -o '"filePath":"[^"]*"' | head -1 | cut -d'"' -f4)
fi

if [ -n "$FILE_PATH" ] && echo "$FILE_PATH" | grep -E '\.rb$' > /dev/null; then
    if ! rubocop "$FILE_PATH" > /dev/null 2>&1; then
        echo "RUBOCOP VIOLATION in $FILE_PATH"
        rubocop "$FILE_PATH"
        exit 1
    fi

    case "$FILE_PATH" in
        *_test.rb)
            if ! rails test "$FILE_PATH" > /dev/null 2>&1; then
                echo "TEST FAILURE in $FILE_PATH"
                rails test "$FILE_PATH"
                exit 1
            fi
            ;;
        *)
            TEST_FILE=$(echo "$FILE_PATH" | sed 's|^app/|test/|' | sed 's|\.rb$|_test.rb|')
            if [ -f "$TEST_FILE" ]; then
                if ! rails test "$TEST_FILE" > /dev/null 2>&1; then
                    echo "TEST FAILURE in $TEST_FILE"
                    rails test "$TEST_FILE"
                    exit 1
                fi
            fi
            ;;
    esac
fi

log_result 0 "Check completed successfully"
exit 0
