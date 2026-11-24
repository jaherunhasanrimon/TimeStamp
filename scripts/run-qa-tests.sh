#!/bin/bash
set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

echo "======================================================="
echo "   Running TimeStamp Automated QA Audit Suite"
echo "======================================================="

# Ensure debug build objects exist
swift build > /dev/null 2>&1

# Compile and run QA test runner
swiftc -parse-as-library \
  -I .build/arm64-apple-macosx/debug/Modules \
  -L .build/arm64-apple-macosx/debug \
  -F /Library/Developer/CommandLineTools/Library/Developer/Frameworks \
  -Xlinker -rpath -Xlinker /Library/Developer/CommandLineTools/Library/Developer/Frameworks \
  -Xlinker -rpath -Xlinker /Library/Developer/CommandLineTools/Library/Developer/usr/lib \
  -framework SwiftUI -framework AppKit -framework Foundation \
  Tests/QAAuditRunner.swift \
  .build/arm64-apple-macosx/debug/TimeStamp.build/*.o \
  -o .build/qa_runner

.build/qa_runner
rm -f .build/qa_runner
