#!/bin/bash
source "$CLAUDE_PROJECT_DIR/.claude/hooks/log_hook.sh" "controller_response_check"

cd "$CLAUDE_PROJECT_DIR"

STDIN_DATA=$(cat)
FILE_PATH=$(echo "$STDIN_DATA" | grep -o '"file_path":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$FILE_PATH" ]; then
    FILE_PATH=$(echo "$STDIN_DATA" | grep -o '"filePath":"[^"]*"' | head -1 | cut -d'"' -f4)
fi

if [[ ! "$FILE_PATH" =~ app/controllers/.*\.rb$ ]]; then
    exit 0
fi

if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

if grep -E 'format\.json|render.*json:|to_json|as_json|format\.xml|render.*xml:|api_only' "$FILE_PATH" > /dev/null 2>&1; then
    echo "PATTERN VIOLATION: API response detected in $FILE_PATH"
    echo "   This is a full Rails application with Turbo, not an API!"
    echo "   We use server-side rendering with HTML and Turbo Streams."
    echo ""
    echo "   Instead of JSON/XML/API responses:"
    echo "   - Use Turbo Streams for dynamic updates"
    echo "   - Use HTML responses for full page renders"
    echo "   - Let Turbo handle the interactivity"
    echo ""
    echo "   Valid response formats:"
    echo "   - format.html for full page responses"
    echo "   - format.turbo_stream for partial updates"
    exit 1
fi

if grep -q "respond_to do |format|" "$FILE_PATH"; then
    if grep -A 10 "respond_to do |format|" "$FILE_PATH" | grep -q "format\.json"; then
        echo "PATTERN VIOLATION: format.json in respond_to block"
        echo "   We don't serve JSON in this application!"
        echo "   Remove format.json and use HTML/Turbo Streams only."
        exit 1
    fi

    if grep -A 10 "respond_to do |format|" "$FILE_PATH" | grep -q "format\.turbo_stream"; then
        echo "OK: Valid respond_to block with format.turbo_stream detected"
        echo "TURBO INFO: Using respond_to with format.turbo_stream"
        echo "   This is a valid Rails pattern for handling multiple formats."
        echo "   Ensure you have a corresponding .turbo_stream.erb template"
        echo "   or use inline rendering: format.turbo_stream { render turbo_stream: ... }"

        if ! grep -A 10 "respond_to do |format|" "$FILE_PATH" | grep -q "format\.html"; then
            echo "WARNING: respond_to block without format.html"
            echo "   Include format.html to avoid ActionController::UnknownFormat errors"
        fi
    else
        echo "TURBO WARNING: respond_to block without format.turbo_stream"
        echo "   If you're only handling HTML, you might not need respond_to:"
        echo "   - Just use redirect_to or render directly for HTML-only responses"
        echo "   - Add format.turbo_stream if you need to handle Turbo Stream requests"
    fi
fi

if grep -E 'render.*turbo_stream:' "$FILE_PATH" > /dev/null 2>&1; then
    if ! grep -E 'turbo_stream\.(append|prepend|replace|update|remove|before|after)' "$FILE_PATH" > /dev/null 2>&1; then
        echo "TURBO WARNING: Rendering turbo_stream without proper action"
        echo "Use turbo_stream builder methods:"
        echo "   - turbo_stream.append(target, partial: ...)"
        echo "   - turbo_stream.prepend(target, partial: ...)"
        echo "   - turbo_stream.replace(target, partial: ...)"
        echo "   - turbo_stream.update(target, partial: ...)"
        echo "   - turbo_stream.remove(target)"
    fi
fi

if grep -E 'broadcast_(append|prepend|replace|update|remove)_to' "$FILE_PATH" > /dev/null 2>&1; then
    echo "TURBO WARNING: Broadcasting directly from controller"
    echo "Consider:"
    echo "   - Move broadcasts to model callbacks for data changes"
    echo "   - Use turbo_stream responses for immediate updates"
    echo "   - Broadcasting from controllers can cause duplicate updates"
fi

if grep -E 'redirect_to.*turbo_stream' "$FILE_PATH" > /dev/null 2>&1; then
    echo "TURBO VIOLATION: Cannot redirect with Turbo Streams"
    echo "Turbo Streams must render, not redirect"
    echo "   Use: render turbo_stream: ..."
    echo "   Not: redirect_to ..., turbo_stream: ..."
    exit 1
fi

if grep -E '(hotwire_native_app\?|recede_or_redirect|resume_or_redirect|refresh_or_redirect)' "$FILE_PATH" > /dev/null 2>&1; then
    echo "TURBO NATIVE: Mobile app integration detected"
    echo "Native navigation methods:"
    echo "   - hotwire_native_app? - Detects native app requests"
    echo "   - recede_or_redirect_to - Dismisses modals/pops navigation"
    echo "   - resume_or_redirect_to - Tells app to ignore navigation"
    echo "   - refresh_or_redirect_to - Refreshes current screen"
    echo "   Each has a _back_or_to variant for fallback handling"
fi

if grep -E 'turbo_stream\.(append|prepend|replace|update|remove|before|after|refresh)' "$FILE_PATH" > /dev/null 2>&1; then
    if grep -E 'turbo_stream\.(append|prepend|replace|update|remove|before|after)_all' "$FILE_PATH" > /dev/null 2>&1; then
        echo "TURBO INFO: Using _all variant for multiple targets"
        echo "   Ensure CSS selector targets multiple elements"
    fi
fi

log_result 0 "Check completed successfully"
exit 0
