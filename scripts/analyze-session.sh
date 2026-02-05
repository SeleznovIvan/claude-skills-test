#!/bin/bash
# analyze-session.sh - Analyze a Claude session for Skill tool usage
# Usage: ./analyze-session.sh <session_id>

SESSION_ID="$1"

if [[ -z "$SESSION_ID" ]]; then
    echo "Usage: $0 <session_id>"
    exit 1
fi

echo "=== Session Analysis: $SESSION_ID ==="
echo ""

# Find the session log file
LOG_DIR="$HOME/.claude/projects"
LOG_FILE=$(find "$LOG_DIR" -name "${SESSION_ID}.jsonl" 2>/dev/null | head -1)

if [[ -z "$LOG_FILE" ]]; then
    echo "Log file not found for session: $SESSION_ID"
    exit 1
fi

echo "Log file: $LOG_FILE"
echo ""

# Look for Skill tool usage
echo "=== Skill Tool Invocations ==="
grep -o '"tool_use"[^}]*"name":"Skill"[^}]*' "$LOG_FILE" 2>/dev/null | head -5

# Look for skill content being loaded
echo ""
echo "=== Skill Content Loaded ==="
grep -o 'skills/[^/"]*' "$LOG_FILE" 2>/dev/null | sort -u

# Show tool calls summary
echo ""
echo "=== All Tool Calls ==="
grep -o '"name":"[^"]*"' "$LOG_FILE" 2>/dev/null | grep -v '"name":"' | sort | uniq -c | sort -rn | head -10
