#!/bin/bash
# Kill Shade app if running

killall Shade 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✓ Shade stopped"
else
    echo "Shade not running"
fi
