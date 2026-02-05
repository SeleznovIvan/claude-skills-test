#!/bin/bash
# baseline-test.sh - Test skill activation without hook

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS_FILE="$SCRIPT_DIR/.claude/settings.json"
SETTINGS_BACKUP="$SCRIPT_DIR/.claude/settings.json.bak"

# Temporarily disable hook by moving settings.json
if [[ -f "$SETTINGS_FILE" ]]; then
    mv "$SETTINGS_FILE" "$SETTINGS_BACKUP"
    trap "mv '$SETTINGS_BACKUP' '$SETTINGS_FILE' 2>/dev/null" EXIT
fi

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

echo "=== Baseline Test (No Hook) ==="
echo "Date: $(date)"
echo ""

correct=0
total=${#queries[@]}

for i in "${!queries[@]}"; do
    query="${queries[$i]}"
    expect="${expected[$i]}"

    echo "--- Test $((i+1)): '$query' ---"
    echo "Expected skill: $expect"

    # Run query with 3 turns and Skill tool allowed
    result=$(claude -p "$query" --max-turns 3 --allowedTools "Skill" --output-format json 2>/dev/null)

    # Extract session_id from JSON
    session_id=$(echo "$result" | python3 -c "import sys, json; print(json.load(sys.stdin).get('session_id', ''))" 2>/dev/null)

    # Check if Skill tool was used successfully
    skill_invoked=""
    skill_denied=""

    # Check for skill content in result (skill was loaded and used)
    if echo "$result" | grep -q "skills/$expect"; then
        skill_invoked="yes"
    fi

    # Check if Skill was in permission_denials specifically
    if echo "$result" | python3 -c "import sys,json; d=json.load(sys.stdin); denials=[x['tool_name'] for x in d.get('permission_denials',[])]; exit(0 if 'Skill' in denials else 1)" 2>/dev/null; then
        skill_denied="yes"
    fi

    if [[ "$skill_invoked" == "yes" ]]; then
        echo "✓ SKILL ACTIVATED: $expect"
        echo "  Session: $session_id"
        ((correct++))
    elif [[ "$skill_denied" == "yes" ]]; then
        echo "✗ SKILL ATTEMPTED BUT DENIED (expected: $expect)"
        echo "  Session: $session_id"
    else
        echo "✗ SKILL NOT INVOKED (expected: $expect)"
        echo "  Session: $session_id"
    fi
    echo ""
done

echo "=== Results: $correct/$total correct ==="
