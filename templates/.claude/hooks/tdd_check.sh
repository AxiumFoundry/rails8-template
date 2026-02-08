#!/bin/bash
source "$CLAUDE_PROJECT_DIR/.claude/hooks/log_hook.sh" "tdd_check"

cd "$CLAUDE_PROJECT_DIR"

STDIN_DATA=$(cat)

FILE_PATH=$(echo "$STDIN_DATA" | grep -o '"file_path":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$FILE_PATH" ]; then
    FILE_PATH=$(echo "$STDIN_DATA" | grep -o '"filePath":"[^"]*"' | head -1 | cut -d'"' -f4)
fi

if [ -z "$FILE_PATH" ]; then
    exit 0
fi

if echo "$FILE_PATH" | grep -E '\.rb$' | grep -v '_test\.rb$' | grep -v '_spec\.rb$' | grep -v '^test/' | grep -v '^spec/' | grep -v '\.claude/' > /dev/null; then

    if echo "$FILE_PATH" | grep -E 'app/(controllers|models|services|lib)/' > /dev/null; then

        if echo "$FILE_PATH" | grep -q 'app/controllers/'; then
            TEST_FILE=$(echo "$FILE_PATH" | sed 's|app/controllers/|test/controllers/|' | sed 's|\.rb$|_test.rb|')
        elif echo "$FILE_PATH" | grep -q 'app/models/'; then
            TEST_FILE=$(echo "$FILE_PATH" | sed 's|app/models/|test/models/|' | sed 's|\.rb$|_test.rb|')
        elif echo "$FILE_PATH" | grep -q 'app/services/'; then
            TEST_FILE=$(echo "$FILE_PATH" | sed 's|app/services/|test/services/|' | sed 's|\.rb$|_test.rb|')
        elif echo "$FILE_PATH" | grep -q 'app/lib/'; then
            TEST_FILE=$(echo "$FILE_PATH" | sed 's|app/lib/|test/lib/|' | sed 's|\.rb$|_test.rb|')
        else
            TEST_FILE=$(echo "$FILE_PATH" | sed 's|app/|test/|' | sed 's|\.rb$|_test.rb|')
        fi

        if [ ! -f "$TEST_FILE" ]; then
            echo "TDD VIOLATION: No test file exists for $FILE_PATH"
            echo "Expected test file: $TEST_FILE"
            echo "Follow Red-Green-Refactor cycle:"
            echo "   1. RED: Write a failing test first"
            echo "   2. GREEN: Write minimal code to pass"
            echo "   3. REFACTOR: Improve the code"
            echo ""
            echo "WARNING: This is a non-blocking warning to remind you about TDD practices."
            exit 0
        fi
    fi
fi

log_result 0 "Check completed successfully"
exit 0
