#!/bin/bash
# Baseline validation script for ADAMANT iOS
# Run this before committing changes

set -e

echo "🔨 Building project..."
xcodebuild -workspace Adamant.xcworkspace -scheme Adamant -destination 'platform=iOS Simulator,name=iPhone 15' clean build | xcpretty

echo "✅ Running SwiftLint..."
swiftlint

echo "🧪 Running unit tests..."
xcodebuild -workspace Adamant.xcworkspace -scheme Adamant -destination 'platform=iOS Simulator,name=iPhone 15' test | xcpretty

echo "✨ All validations passed!"
