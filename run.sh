#!/bin/bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/.build"
EXECUTABLE="$BUILD_DIR/dependency-visualizer"

mkdir -p "$BUILD_DIR"

xcrun --sdk macosx swiftc \
    "$PROJECT_DIR/src/Configuration.swift" \
    "$PROJECT_DIR/src/YAMLParser.swift" \
    "$PROJECT_DIR/src/main.swift" \
    -o "$EXECUTABLE"

cd "$PROJECT_DIR"
"$EXECUTABLE" "$@"