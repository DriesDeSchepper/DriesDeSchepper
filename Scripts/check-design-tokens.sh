#!/bin/bash
# Fails if any Swift file outside DesignSystem.swift hardcodes a value that
# belongs in the design system: a color, font size, padding/spacing, corner
# radius, stroke width, letter spacing, opacity, or animation timing.
#
# The point is that "no hardcoded values" stays true for screens written
# *after* the token file existed, not just the ones cleaned up when it was
# introduced. Run locally with: ./Scripts/check-design-tokens.sh
#
# If you're hitting this on a value that genuinely doesn't belong in the
# design system, add the token instead of suppressing the check — that's
# the whole mechanism. `spacing: 0` is allowed (it means "no gap", not a
# spacing choice), as are gradient stops at `.opacity(0)`.

set -uo pipefail
cd "$(dirname "$0")/.."

FILES=$(find TempoRep -name '*.swift' ! -name 'DesignSystem.swift')
STATUS=0

check() {
  local label="$1" pattern="$2"
  # shellcheck disable=SC2086
  local hits
  hits=$(grep -nE "$pattern" $FILES || true)
  if [ -n "$hits" ]; then
    echo "✗ $label — use a token from DesignSystem.swift instead:"
    echo "$hits" | sed 's/^/    /'
    STATUS=1
  fi
}

check "hardcoded font size"     '\.system\(size: [0-9]'
check "hardcoded frame size"    'frame\((width|height|minWidth|minHeight): [0-9]'
check "hardcoded padding"       'padding\([^)]*[0-9]+\)'
check "hardcoded stack spacing" 'spacing: [1-9][0-9]*[,)]'
check "hardcoded corner radius" 'cornerRadius: [0-9]'
check "hardcoded stroke width"  'lineWidth: [0-9]'
check "hardcoded tracking"      'tracking\([0-9]'
check "hardcoded scale factor"  'minimumScaleFactor\([0-9]'
check "hardcoded color"         'Color\.(black|white|red|green|blue|gray|yellow|orange|purple)|Color\(red:|foregroundStyle\(\.(black|white|yellow|red|green|blue)\)'
check "hardcoded opacity"       '\.opacity\(0\.[0-9]'
check "hardcoded animation"     '\.easeInOut\(|\.easeOut\(|\.spring\('

if [ "$STATUS" -eq 0 ]; then
  echo "✓ No hardcoded design values outside DesignSystem.swift"
fi
exit "$STATUS"
