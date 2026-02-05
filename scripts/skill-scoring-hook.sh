#!/bin/bash
# skill-scoring-hook.sh - UserPromptSubmit hook using scoring algorithm

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}"
SCORE_SCRIPT="${PROJECT_DIR}/score.sh"
SKILLS_DIR="${PROJECT_DIR}/.claude/skills"

# Read user prompt from stdin (JSON format)
input=$(cat)

# Extract prompt from JSON - handle both formats
# Format 1: {"prompt": "..."}
# Format 2: {"session_id": "...", "prompt": "..."}
prompt=$(echo "$input" | python3 -c "import sys, json; data = json.load(sys.stdin); print(data.get('prompt', ''))" 2>/dev/null)

# If extraction failed, try a simpler approach
if [[ -z "$prompt" ]]; then
    prompt=$(echo "$input" | grep -o '"prompt"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"prompt"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
fi

# Exit if no prompt
[[ -z "$prompt" ]] && exit 0

# Check if score.sh exists
if [[ ! -x "$SCORE_SCRIPT" ]]; then
    exit 0
fi

# Check if skills directory exists
if [[ ! -d "$SKILLS_DIR" ]]; then
    exit 0
fi

# Run scoring algorithm and extract top result
# score.sh outputs: "Query: ...", "Skills dir: ...", "", "skill_name:score" lines
# Strip ANSI color codes from output
scores=$("$SCORE_SCRIPT" "$prompt" "$SKILLS_DIR" 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g')

# Get the first skill line (highest score) - skip the header lines
top_result=$(echo "$scores" | grep ':' | grep -v "^Query:" | grep -v "^Skills dir:" | head -1)

if [[ -n "$top_result" ]]; then
    skill_name=$(echo "$top_result" | cut -d: -f1)
    skill_score=$(echo "$top_result" | cut -d: -f2)

    # If score above threshold (default: 5), inject instruction
    if [[ -n "$skill_name" && -n "$skill_score" && "$skill_score" -ge 5 ]]; then
        echo "INSTRUCTION: The skill '$skill_name' matches this request (score: $skill_score). Use the Skill tool to invoke /$skill_name before proceeding."
    fi
fi
