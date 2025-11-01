#!/bin/bash
# Run Shade app in foreground or background

MODE="${1:-foreground}"

cd "$(dirname "$0")/.."

# Get build products directory
BUILD_DIR=$(xcodebuild -project ShadeApp/Shade.xcodeproj \
                       -scheme Shade \
                       -showBuildSettings 2>/dev/null | \
            grep ' BUILT_PRODUCTS_DIR =' | \
            sed 's/.*= //')

SHADE_APP="$BUILD_DIR/Shade.app/Contents/MacOS/Shade"

if [ ! -f "$SHADE_APP" ]; then
    echo "Error: Shade app not found at $SHADE_APP"
    echo "Run scripts/build-shade.sh first"
    exit 1
fi

case "$MODE" in
    background|bg)
        echo "Starting Shade in background..."
        nohup "$SHADE_APP" > /dev/null 2>&1 &
        SHADE_PID=$!
        sleep 0.5  # Give app time to start
        if kill -0 $SHADE_PID 2>/dev/null; then
            echo "Shade PID: $SHADE_PID"
        else
            echo "Warning: Shade may have exited immediately"
        fi
        ;;
    foreground|fg|*)
        echo "Starting Shade in foreground..."
        exec "$SHADE_APP"
        ;;
esac
