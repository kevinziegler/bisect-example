#!/usr/bin/env bash
set -euo pipefail

if [ -f "i-must-exist.txt" ]; then
    echo "Test PASSED";
    exit 0;
else
    echo "Test FAILED";
    exit 1;
fi
