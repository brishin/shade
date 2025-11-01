#!/bin/bash
# Check if Shade is running and show PID

if pgrep -x Shade > /dev/null; then
    PID=$(pgrep -x Shade)
    echo "✓ Shade is running (PID: $PID)"
    exit 0
else
    echo "✗ Shade is not running"
    exit 1
fi
