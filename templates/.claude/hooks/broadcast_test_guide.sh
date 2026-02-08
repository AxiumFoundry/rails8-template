#!/bin/bash
source "$CLAUDE_PROJECT_DIR/.claude/hooks/log_hook.sh" "broadcast_test_guide"

cd "$CLAUDE_PROJECT_DIR"

STDIN_DATA=$(cat)
FILE_PATH=$(echo "$STDIN_DATA" | grep -o '"file_path":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$FILE_PATH" ]; then
    FILE_PATH=$(echo "$STDIN_DATA" | grep -o '"filePath":"[^"]*"' | head -1 | cut -d'"' -f4)
fi

if [[ ! "$FILE_PATH" =~ test/.*_test\.rb$ ]]; then
    exit 0
fi

if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

if echo "$FILE_PATH" | grep -E 'test/models/.*_test\.rb$' > /dev/null; then
    MODEL_FILE=$(echo "$FILE_PATH" | sed 's|test/models/|app/models/|' | sed 's|_test\.rb|.rb|')

    if [ -f "$MODEL_FILE" ]; then
        if grep -E '(broadcasts_refreshes|broadcasts_to)' "$MODEL_FILE" > /dev/null 2>&1; then
            echo "TURBO BROADCAST TESTING GUIDE:"
            echo ""
            echo "Model uses broadcasting. Test patterns from Turbo::Broadcastable docs:"
            echo ""
            echo "For broadcasts_refreshes:"
            echo "  test 'broadcasts refresh on update' do"
            echo "    assert_broadcast_on(@model, :refresh) do"
            echo "      @model.update!(name: 'New Name')"
            echo "    end"
            echo "  end"
            echo ""
            echo "For broadcast_*_later methods (async):"
            echo "  test 'enqueues broadcast job' do"
            echo "    assert_enqueued_with(job: Turbo::Streams::BroadcastJob) do"
            echo "      @model.destroy"
            echo "    end"
            echo "  end"
            echo ""
            echo "For suppressing broadcasts in tests:"
            echo "  @model.suppressing_turbo_broadcasts do"
            echo "    @model.update!(name: 'Silent Update')"
            echo "  end"
            echo ""
            echo "Docs: https://rubydoc.info/github/hotwired/turbo-rails/main/Turbo/Broadcastable"
        fi

        if grep -E 'broadcast_(append|prepend|replace|update|remove)(_later)?_to' "$MODEL_FILE" > /dev/null 2>&1; then
            if ! grep -E '(assert_broadcast_on|assert_no_broadcasts|perform_enqueued_jobs|assert_enqueued_with)' "$FILE_PATH" > /dev/null 2>&1; then
                echo ""
                echo "WARNING: Model has custom broadcast methods but tests don't verify them"
                echo "Add assertions for your broadcast methods"
            fi
        fi
    fi
fi

if echo "$FILE_PATH" | grep -E 'test/(controllers|integration)/.*_test\.rb$' > /dev/null; then
    if grep -E 'post|patch|put|delete' "$FILE_PATH" > /dev/null 2>&1; then
        if grep -E 'turbo_stream' "$FILE_PATH" > /dev/null 2>&1; then
            echo "TURBO STREAM RESPONSE TESTING:"
            echo ""
            echo "Available Turbo TestAssertions:"
            echo ""
            echo "assert_turbo_stream - Check for turbo-stream elements:"
            echo "  assert_turbo_stream action: 'append', target: 'messages'"
            echo ""
            echo "assert_no_turbo_stream - Verify absence of turbo-stream:"
            echo "  assert_no_turbo_stream action: 'remove', target: 'message_1'"
            echo ""
            echo "Test with headers for Turbo Stream format:"
            echo "  post items_url, params: { item: { name: 'Test' } },"
            echo "                  headers: { 'Accept' => 'text/vnd.turbo-stream.html' }"
        fi
    fi
fi

if echo "$FILE_PATH" | grep -E 'test/system/.*_test\.rb$' > /dev/null; then
    echo "TURBO SYSTEM TEST PATTERNS:"
    echo ""
    echo "System tests automatically handle Turbo interactions."
    echo ""
    echo "Test Turbo Frame navigation:"
    echo "  click_link 'Edit', match: :first"
    echo "  assert_selector 'turbo-frame#item_1 form'"
    echo ""
    echo "Test broadcasts with connected WebSocket:"
    echo "  item.broadcast_append_to 'items'"
    echo "  assert_selector '#items .item', count: 2"
fi

log_result 0 "Check completed successfully"
exit 0
