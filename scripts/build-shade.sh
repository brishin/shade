#!/bin/bash
# Build Shade and return status

set -e

cd "$(dirname "$0")/.."

echo "Building Shade..."
xcodebuild -project ShadeApp/Shade.xcodeproj \
           -scheme Shade \
           -configuration Debug \
           build 2>&1 | grep -E "^\*\*|error:|warning:|BUILD SUCCEEDED|BUILD FAILED"

exit ${PIPESTATUS[0]}
