#!/bin/bash
# hook-test.sh - Test skill activation WITH hook

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Same queries as baseline
queries=(
    "use svelte5 runes to create a counter"
    "create reactive state with \$state"
    "write a dockerfile for node app"
    "resolve git merge conflict"
)

expected=(
    "svelte5-runes"
    "svelte5-runes"
    "dockerfile-generator"
    "git-workflow"
)

echo "=== Hook Test (With Scoring Hook) ==="
echo "Date: $(date)"
echo ""

correct=0
total=${#queries[@]}

# Store session IDs for later analysis
declare -a session_ids
declare -a results_json

for i in "${!queries[@]}"; do
    query="${queries[$i]}"
    expect="${expected[$i]}"

    echo "--- Test $((i+1)): '$query' ---"
    echo "Expected skill: $expect"

    # Run query with 3 turns and Skill tool allowed
    result=$(claude -p "$query" --max-turns 3 --allowedTools "Skill" --output-format json 2>/dev/null)
    results_json+=("$result")

    # Extract session_id and other info from JSON
    session_id=$(echo "$result" | python3 -c "import sys, json; print(json.load(sys.stdin).get('session_id', ''))" 2>/dev/null)
    session_ids+=("$session_id")

    subtype=$(echo "$result" | python3 -c "import sys, json; print(json.load(sys.stdin).get('subtype', ''))" 2>/dev/null)
    num_turns=$(echo "$result" | python3 -c "import sys, json; print(json.load(sys.stdin).get('num_turns', 0))" 2>/dev/null)

    # Check permission denials for Skill specifically
    skill_denied=$(echo "$result" | python3 -c "
import sys, json
d = json.load(sys.stdin)
denials = d.get('permission_denials', [])
skill_denials = [x for x in denials if x.get('tool_name') == 'Skill']
if skill_denials:
    print('yes')
    for sd in skill_denials:
        print('  Skill input:', sd.get('tool_input', {}))
" 2>/dev/null)

    echo "  Session: $session_id"
    echo "  Status: $subtype, Turns: $num_turns"

    if [[ -n "$skill_denied" ]]; then
        echo "  ✗ SKILL ATTEMPTED BUT DENIED"
        echo "$skill_denied"
    else
        # If not denied, assume success (verify with logs)
        echo "  → Verify skill usage with: analyze session $session_id"
        ((correct++))
        echo "  ✓ PRESUMED SKILL ACTIVATED (no Skill denial)"
    fi
    echo ""
done

echo "=== Results: $correct/$total (presumed, verify with logs) ==="
echo ""
echo "=== Session IDs for log verification ==="
for i in "${!session_ids[@]}"; do
    echo "Test $((i+1)): ${session_ids[$i]} (expected: ${expected[$i]})"
done
