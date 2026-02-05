#!/bin/bash
# compare-results.sh - Compare baseline vs hook test results

RESULTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/results"

echo "=== COMPARISON ==="
echo ""

baseline_file="$RESULTS_DIR/baseline.txt"
hook_file="$RESULTS_DIR/with-hook.txt"

if [[ -f "$baseline_file" ]]; then
    baseline_correct=$(grep -c "^✓" "$baseline_file" 2>/dev/null) || baseline_correct=0
    baseline_total=$(grep -cE "^[✓✗]" "$baseline_file" 2>/dev/null) || baseline_total=0
    echo "Baseline (no hook): $baseline_correct/$baseline_total"
else
    echo "Baseline (no hook): [not run yet]"
fi

if [[ -f "$hook_file" ]]; then
    hook_correct=$(grep -c "^✓" "$hook_file" 2>/dev/null) || hook_correct=0
    hook_total=$(grep -cE "^[✓✗]" "$hook_file" 2>/dev/null) || hook_total=0
    echo "With hook:          $hook_correct/$hook_total"
else
    echo "With hook:          [not run yet]"
fi

echo ""
echo "=== DETAILS ==="
echo ""

if [[ -f "$baseline_file" ]]; then
    echo "--- Baseline results ---"
    cat "$baseline_file"
    echo ""
fi

if [[ -f "$hook_file" ]]; then
    echo "--- Hook results ---"
    cat "$hook_file"
fi
