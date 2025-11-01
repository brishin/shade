#!/bin/bash

# Shade Log Viewer
# Usage: ./scripts/watch-logs.sh [category]
# Categories: all, permissions, windows, lifecycle

CATEGORY="${1:-all}"

echo "🔍 Watching Shade logs (category: $CATEGORY)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

case "$CATEGORY" in
    permissions)
        echo "Filtering: 🔐 Accessibility permissions only"
        log stream --predicate 'subsystem == "com.brishin.Shade" AND category == "AccessibilityManager"' --style compact
        ;;
    windows)
        echo "Filtering: 🪟 Window enumeration only"
        log stream --predicate 'subsystem == "com.brishin.Shade" AND category == "WindowManager"' --style compact
        ;;
    lifecycle)
        echo "Filtering: 🚀 App lifecycle only"
        log stream --predicate 'subsystem == "com.brishin.Shade" AND category == "AppLifecycle"' --style compact
        ;;
    all|*)
        echo "Showing: All Shade logs"
        log stream --predicate 'subsystem == "com.brishin.Shade"' --style compact
        ;;
esac
