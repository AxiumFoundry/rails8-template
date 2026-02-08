#!/bin/bash
source "$CLAUDE_PROJECT_DIR/.claude/hooks/log_hook.sh" "rails_test_guide"

cd "$CLAUDE_PROJECT_DIR"

STDIN_DATA=$(cat)

FILE_PATH=$(echo "$STDIN_DATA" | grep -o '"file_path":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$FILE_PATH" ]; then
    FILE_PATH=$(echo "$STDIN_DATA" | grep -o '"filePath":"[^"]*"' | head -1 | cut -d'"' -f4)
fi

if [ -n "$FILE_PATH" ]; then
    if [[ "$FILE_PATH" == *"/test/"* ]] && [[ "$FILE_PATH" == *"_test.rb" || "$FILE_PATH" == *"_test_case.rb" ]]; then
        echo "RAILS 8 TESTING DOCUMENTATION REQUIRED:"
        echo ""
        echo "MANDATORY: Review Rails Testing Guide before writing tests!"
        echo "URL: https://guides.rubyonrails.org/testing.html"
        echo ""
        echo "Rails 8 Test Structure:"
        echo "- test/models/ - Model unit tests (ActiveSupport::TestCase)"
        echo "- test/controllers/ - Controller tests (ActionDispatch::IntegrationTest)"
        echo "- test/system/ - System tests (ActionDispatch::SystemTestCase)"
        echo "- test/integration/ - Integration tests"
        echo "- test/application_system_test_case.rb - Base class for system tests"
        echo ""
        echo "This project specifics:"
        echo "- FactoryBot for test data"
        echo "- Minitest framework"
        echo "- Devise::Test::IntegrationHelpers for auth"
        echo ""
        echo "WARNING: DO NOT skip reading the documentation!"
    fi
fi

log_result 0 "Check completed successfully"
exit 0
