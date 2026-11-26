#!/bin/bash
set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

echo "======================================================="
echo "   Building & Running ALL TimeStamp Swift Testing Suites"
echo "======================================================="

# Compile main target + all test object files
swift test --enable-swift-testing --disable-xctest

# Link and run native Swift Testing executable against compiled test & app objects
swiftc -parse-as-library \
  -I .build/arm64-apple-macosx/debug/Modules \
  -F /Library/Developer/CommandLineTools/Library/Developer/Frameworks \
  -Xlinker -rpath -Xlinker /Library/Developer/CommandLineTools/Library/Developer/Frameworks \
  -Xlinker -rpath -Xlinker /Library/Developer/CommandLineTools/Library/Developer/usr/lib \
  -framework Testing \
  -framework SwiftUI \
  -framework AppKit \
  -framework Foundation \
  -o .build/all_tests_runner \
  -e 'import Foundation; import Testing; @main struct Runner { static func main() async { let code: CInt = await Testing.__swiftPMEntryPoint(); exit(code) } }' \
  .build/arm64-apple-macosx/debug/TimeStampTests.build/*.o \
  .build/arm64-apple-macosx/debug/TimeStamp.build/*.o

./.build/all_tests_runner
rm -f .build/all_tests_runner
