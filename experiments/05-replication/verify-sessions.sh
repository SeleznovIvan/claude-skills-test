#!/bin/bash
# verify-sessions.sh - Verify skill invocation for all experiment sessions using cclogviewer CLI

DATA_DIR="$(dirname "$0")/data"
OUTPUT_DIR="$(dirname "$0")/verified"

mkdir -p "$OUTPUT_DIR"

echo "=========================================="
echo "Session Verification Script"
echo "=========================================="
echo ""

# Results file
RESULTS_FILE="$OUTPUT_DIR/verified_results.jsonl"
> "$RESULTS_FILE"

# Counters
total=0
skill_invoked=0
skill_not_invoked=0

# Process all results files
for results_file in "$DATA_DIR"/*/results.jsonl; do
    condition=$(basename "$(dirname "$results_file")")
    echo "Processing condition: $condition"

    while IFS= read -r line; do
        session_id=$(echo "$line" | jq -r '.session_id')

        if [[ -z "$session_id" || "$session_id" == "null" ]]; then
            continue
        fi

        total=$((total + 1))

        # Get tool usage stats from cclogviewer
        tool_output=$(cclogviewer tools --json "$session_id" 2>/dev/null)

        # Check if "Skill" tool is in the tools list
        skill_count=$(echo "$tool_output" | jq '[.tools[]? | select(.name == "Skill")] | length' 2>/dev/null || echo "0")

        if [[ "$skill_count" -gt 0 ]]; then
            skill_invoked=$((skill_invoked + 1))
            skill_used="true"
        else
            skill_not_invoked=$((skill_not_invoked + 1))
            skill_used="false"
            tools_used=$(echo "$tool_output" | jq -r '[.tools[]?.name] | join(", ")' 2>/dev/null || echo "unknown")
            echo "  [NO SKILL] $session_id - Tools: $tools_used"
        fi

        # Write verified result
        echo "$line" | jq -c --arg skill "$skill_used" '. + {skill_invoked_verified: ($skill == "true")}' >> "$RESULTS_FILE"

        # Progress every 50
        if (( total % 50 == 0 )); then
            echo "  Progress: $total sessions ($skill_invoked skill, $skill_not_invoked no skill)"
        fi

    done < "$results_file"
done

echo ""
echo "=========================================="
echo "VERIFICATION COMPLETE"
echo "=========================================="
echo ""
echo "Total sessions:       $total"
echo "Skill invoked:        $skill_invoked"
echo "Skill NOT invoked:    $skill_not_invoked"

if [[ $((skill_invoked + skill_not_invoked)) -gt 0 ]]; then
    rate=$(echo "scale=2; $skill_invoked * 100 / ($skill_invoked + $skill_not_invoked)" | bc)
    echo "Activation rate:      ${rate}%"
fi

echo ""
echo "Results saved to: $RESULTS_FILE"

# Generate summary JSON
cat > "$OUTPUT_DIR/verification_summary.json" << EOF
{
  "total_sessions": $total,
  "skill_invoked": $skill_invoked,
  "skill_not_invoked": $skill_not_invoked,
  "activation_rate": $(echo "scale=6; $skill_invoked / ($skill_invoked + $skill_not_invoked)" | bc 2>/dev/null || echo "0")
}
EOF

echo "Summary saved to: $OUTPUT_DIR/verification_summary.json"
