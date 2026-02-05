#!/bin/bash
# skill-test-runner.sh - Run skill activation tests using test-cases.json from each skill
# Usage: ./skill-test-runner.sh [--no-hook] [--max-cases N]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/.claude/skills"
SETTINGS_FILE="$SCRIPT_DIR/.claude/settings.json"
SETTINGS_BACKUP="$SCRIPT_DIR/.claude/settings.json.bak"
RESULTS_DIR="$SCRIPT_DIR/results"

# Parse arguments
NO_HOOK=false
MAX_CASES=0  # 0 = unlimited

while [[ $# -gt 0 ]]; do
    case $1 in
        --no-hook)
            NO_HOOK=true
            shift
            ;;
        --max-cases)
            MAX_CASES="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Setup
mkdir -p "$RESULTS_DIR"

if [[ "$NO_HOOK" == "true" ]]; then
    TEST_TYPE="baseline"
    echo "=== BASELINE TEST (No Hook) ==="
    # Temporarily disable hook
    if [[ -f "$SETTINGS_FILE" ]]; then
        mv "$SETTINGS_FILE" "$SETTINGS_BACKUP"
        trap "mv '$SETTINGS_BACKUP' '$SETTINGS_FILE' 2>/dev/null" EXIT
    fi
else
    TEST_TYPE="hook"
    echo "=== HOOK TEST (With Scoring Hook) ==="
fi

echo "Date: $(date)"
echo "Skills directory: $SKILLS_DIR"
echo ""

# Results storage
RESULTS_JSON="$RESULTS_DIR/${TEST_TYPE}-results.json"
echo '{"test_type": "'$TEST_TYPE'", "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'", "tests": [' > "$RESULTS_JSON"

first_test=true
total_tests=0
total_skill_invoked=0

# Process each skill directory
for skill_dir in "$SKILLS_DIR"/*/; do
    skill_name=$(basename "$skill_dir")
    test_cases_file="$skill_dir/test-cases.json"

    if [[ ! -f "$test_cases_file" ]]; then
        echo "Warning: No test-cases.json in $skill_name, skipping"
        continue
    fi

    echo "=== Skill: $skill_name ==="

    # Read test cases
    cases=$(cat "$test_cases_file")
    num_cases=$(echo "$cases" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))")

    # Limit cases if specified
    if [[ $MAX_CASES -gt 0 && $num_cases -gt $MAX_CASES ]]; then
        num_cases=$MAX_CASES
    fi

    for ((i=0; i<num_cases; i++)); do
        query=$(echo "$cases" | python3 -c "import sys,json; print(json.load(sys.stdin)[$i]['query'])")
        why=$(echo "$cases" | python3 -c "import sys,json; print(json.load(sys.stdin)[$i]['why'])")

        ((total_tests++))
        echo ""
        echo "--- Test $total_tests: '$query' ---"
        echo "Expected: $skill_name | Reason: $why"

        # Run claude -p with 2 turns (Skill should activate on first turn)
        result=$(claude -p "$query" --max-turns 2 --allowedTools "Skill" --output-format json 2>/dev/null)

        # Extract info
        session_id=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('session_id', ''))" 2>/dev/null)
        subtype=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('subtype', ''))" 2>/dev/null)
        num_turns=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('num_turns', 0))" 2>/dev/null)

        # Check for Skill denial
        skill_denied=$(echo "$result" | python3 -c "
import sys, json
d = json.load(sys.stdin)
denials = d.get('permission_denials', [])
skill_denials = [x for x in denials if x.get('tool_name') == 'Skill']
print('yes' if skill_denials else 'no')
" 2>/dev/null)

        echo "  Session: $session_id"
        echo "  Status: $subtype, Turns: $num_turns"

        # Determine result (we'll verify with logs later)
        if [[ "$skill_denied" == "yes" ]]; then
            skill_status="denied"
            echo "  ✗ Skill attempted but DENIED"
        else
            skill_status="presumed_success"
            ((total_skill_invoked++))
            echo "  ✓ Skill presumed invoked (verify with logs)"
        fi

        # Add to JSON results
        if [[ "$first_test" != "true" ]]; then
            echo "," >> "$RESULTS_JSON"
        fi
        first_test=false

        cat >> "$RESULTS_JSON" << EOF
  {
    "test_num": $total_tests,
    "skill": "$skill_name",
    "query": "$query",
    "why": "$why",
    "session_id": "$session_id",
    "status": "$subtype",
    "turns": $num_turns,
    "skill_status": "$skill_status"
  }
EOF
    done
    echo ""
done

# Close JSON
echo ']}' >> "$RESULTS_JSON"

echo "=========================================="
echo "=== SUMMARY: $total_skill_invoked/$total_tests presumed skill invocations ==="
echo "Results saved to: $RESULTS_JSON"
echo "=========================================="
