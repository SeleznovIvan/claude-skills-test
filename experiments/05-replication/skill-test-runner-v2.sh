#!/bin/bash
# skill-test-runner-v2.sh — Single-condition test runner for replication experiment
# Runs 18 queries × N reps with randomization and JSONL output.
#
# Usage:
#   ./skill-test-runner-v2.sh \
#     --variant {a|b|c} --condition {c1|c2|c3|c4} \
#     --reps 10 --max-turns 5 \
#     --output-dir data/a-c1/ \
#     [--resume] [--seed 42] [--delay-ms 500] [--dry-run]
#
# Does NOT swap SKILL.md/CLAUDE.md/settings.json — orchestrator handles that.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILLS_DIR="$PROJECT_ROOT/.claude/skills"

# Defaults
VARIANT=""
CONDITION=""
REPS=1
MAX_TURNS=5
OUTPUT_DIR=""
RESUME=false
SEED=42
DELAY_MS=500
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --variant)    VARIANT="$2"; shift 2 ;;
        --condition)  CONDITION="$2"; shift 2 ;;
        --reps)       REPS="$2"; shift 2 ;;
        --max-turns)  MAX_TURNS="$2"; shift 2 ;;
        --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
        --resume)     RESUME=true; shift ;;
        --seed)       SEED="$2"; shift 2 ;;
        --delay-ms)   DELAY_MS="$2"; shift 2 ;;
        --dry-run)    DRY_RUN=true; shift ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Validate required args
if [[ -z "$VARIANT" || -z "$CONDITION" || -z "$OUTPUT_DIR" ]]; then
    echo "Error: --variant, --condition, and --output-dir are required" >&2
    exit 1
fi

# Ensure output dir exists and set up temp dir
mkdir -p "$OUTPUT_DIR"
RESULTS_FILE="$OUTPUT_DIR/results.jsonl"
TMPDIR_RUNNER=$(mktemp -d)
trap "rm -rf '$TMPDIR_RUNNER'" EXIT

# Write all test cases to a temp file (avoids shell escaping issues with $state etc.)
CASES_FILE="$TMPDIR_RUNNER/cases.json"
python3 -c "
import json, os, glob

skills_dir = os.path.expanduser('$SKILLS_DIR')
all_cases = []
for skill_dir in sorted(glob.glob(os.path.join(skills_dir, '*', ''))):
    skill_name = os.path.basename(skill_dir.rstrip('/'))
    tc_file = os.path.join(skill_dir, 'test-cases.json')
    if not os.path.exists(tc_file):
        continue
    with open(tc_file) as f:
        cases = json.load(f)
    for case in cases:
        all_cases.append({
            'skill': skill_name,
            'query_idx': len(all_cases),
            'query': case['query'],
            'why': case['why']
        })
with open('$CASES_FILE', 'w') as f:
    json.dump(all_cases, f)
print(len(all_cases))
"
NUM_CASES=$(python3 -c "import json; print(len(json.load(open('$CASES_FILE'))))")

echo "=== Runner v2: variant=$VARIANT condition=$CONDITION ==="
echo "  Reps: $REPS, Max turns: $MAX_TURNS, Seed: $SEED"
echo "  Queries: $NUM_CASES, Total trials: $((NUM_CASES * REPS))"
echo "  Output: $RESULTS_FILE"
echo "  Resume: $RESUME, Dry-run: $DRY_RUN"
echo ""

# Build set of completed (rep:query_idx) pairs for resume
COMPLETED_FILE="$TMPDIR_RUNNER/completed.txt"
touch "$COMPLETED_FILE"
if [[ "$RESUME" == "true" && -f "$RESULTS_FILE" ]]; then
    python3 -c "
import json
with open('$RESULTS_FILE') as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            d = json.loads(line)
            # Only skip non-error trials on resume
            if 'error' not in d.get('status', ''):
                print(f\"{d['rep']}:{d['query_idx']}\")
        except:
            pass
" > "$COMPLETED_FILE"
    COMPLETED_COUNT=$(wc -l < "$COMPLETED_FILE" | tr -d ' ')
    echo "  Resume: found $COMPLETED_COUNT completed trials"
fi

# Track progress
trial_order=0
completed_count=0
error_count=0
start_time=$(date +%s)

for ((rep=0; rep<REPS; rep++)); do
    echo ""
    echo "--- Rep $((rep+1))/$REPS ---"

    # Generate shuffled indices for this rep (deterministic)
    SHUFFLED_FILE="$TMPDIR_RUNNER/shuffled_${rep}.txt"
    python3 -c "
import random, json
with open('$CASES_FILE') as f:
    cases = json.load(f)
seed = $SEED * 1000 + $rep
random.seed(seed)
indices = list(range(len(cases)))
random.shuffle(indices)
for i in indices:
    print(i)
" > "$SHUFFLED_FILE"

    while IFS= read -r idx; do
        trial_order=$((trial_order + 1))

        # Extract case details from JSON via Python (safe for special chars)
        CASE_FILE="$TMPDIR_RUNNER/case.json"
        python3 -c "
import json
with open('$CASES_FILE') as f:
    cases = json.load(f)
with open('$CASE_FILE', 'w') as f:
    json.dump(cases[$idx], f)
"
        query=$(python3 -c "import json; print(json.load(open('$CASE_FILE'))['query'])")
        skill=$(python3 -c "import json; print(json.load(open('$CASE_FILE'))['skill'])")
        why=$(python3 -c "import json; print(json.load(open('$CASE_FILE'))['why'])")
        query_idx=$(python3 -c "import json; print(json.load(open('$CASE_FILE'))['query_idx'])")

        # Check if already completed (resume)
        if grep -q "^${rep}:${query_idx}$" "$COMPLETED_FILE" 2>/dev/null; then
            echo "  [skip] rep=$rep query_idx=$query_idx (already completed)"
            completed_count=$((completed_count + 1))
            continue
        fi

        echo "  [$trial_order] rep=$rep q=$query_idx skill=$skill query='$query'"

        if [[ "$DRY_RUN" == "true" ]]; then
            echo "    [dry-run] would run: claude -p '<query>' --max-turns $MAX_TURNS --allowedTools Skill --output-format json"
            continue
        fi

        # Run the trial with error handling and rate-limit retry
        trial_start=$(date +%s)
        RESULT_FILE="$TMPDIR_RUNNER/result.json"
        STDERR_FILE="$TMPDIR_RUNNER/stderr.txt"

        MAX_RETRIES=5
        retry=0
        cli_exit=1
        while [[ $retry -lt $MAX_RETRIES ]]; do
            set +e
            claude -p "$query" --max-turns "$MAX_TURNS" --allowedTools "Skill" --output-format json > "$RESULT_FILE" 2>"$STDERR_FILE"
            cli_exit=$?
            set -e

            # Check for rate limit (exit code != 0 and stderr contains rate/limit/429/overloaded)
            if [[ $cli_exit -ne 0 ]]; then
                stderr_content=$(cat "$STDERR_FILE" 2>/dev/null || echo "")
                if echo "$stderr_content" | grep -iqE "rate|limit|429|overloaded|too many|throttl|retry"; then
                    retry=$((retry + 1))
                    backoff=$((30 * retry))
                    echo "    RATE LIMITED (attempt $retry/$MAX_RETRIES), waiting ${backoff}s..."
                    sleep "$backoff"
                    continue
                fi
            fi
            break
        done

        trial_end=$(date +%s)
        wall_time_ms=$(( (trial_end - trial_start) * 1000 ))

        # Parse result and write JSONL line (all in Python for safety)
        set +e
        python3 -c "
import json, sys
from datetime import datetime, timezone

case = json.load(open('$CASE_FILE'))
variant = '$VARIANT'
condition = '$CONDITION'
rep = $rep
trial_order = $trial_order
seed = $SEED
wall_time_ms = $wall_time_ms
cli_exit = $cli_exit
timestamp = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')

session_id = ''
status = 'success'
num_turns = 0
skill_invoked = False
error_msg = ''

if cli_exit != 0:
    status = 'error_cli'
    error_msg = f'CLI exit code: {cli_exit}'
else:
    try:
        with open('$RESULT_FILE') as f:
            content = f.read().strip()
        d = json.loads(content)
        session_id = d.get('session_id', '')
        subtype = d.get('subtype', '')
        num_turns = d.get('num_turns', 0)

        # Check for skill denial
        denials = d.get('permission_denials', [])
        skill_denials = [x for x in denials if x.get('tool_name') == 'Skill']
        skill_denied = len(skill_denials) > 0

        # Heuristic: skill invoked if no denial and turns > 0
        skill_invoked = not skill_denied and num_turns > 0

        if subtype == 'error_max_turns':
            status = 'error_max_turns'
        elif subtype:
            status = subtype
        else:
            status = 'success'
    except Exception as e:
        status = 'error_parse'
        error_msg = str(e)

line = {
    'variant': variant,
    'condition': condition,
    'rep': rep,
    'query_idx': case['query_idx'],
    'query': case['query'],
    'skill': case['skill'],
    'why': case['why'],
    'session_id': session_id,
    'status': status,
    'turns': num_turns,
    'skill_invoked_heuristic': skill_invoked,
    'timestamp': timestamp,
    'wall_time_ms': wall_time_ms,
    'trial_order': trial_order,
    'seed': seed,
    'error_msg': error_msg if error_msg else None
}

with open('$RESULTS_FILE', 'a') as f:
    f.write(json.dumps(line) + '\n')

# Signal status to shell
if 'error' in status:
    sys.exit(1)
" 2>/dev/null
        parse_exit=$?
        set -e

        if [[ $parse_exit -ne 0 ]]; then
            error_count=$((error_count + 1))
            echo "    ERROR (see JSONL for details)"
        else
            completed_count=$((completed_count + 1))
            # Read back last line for display
            last_line=$(tail -1 "$RESULTS_FILE")
            sess=$(python3 -c "import json; print(json.loads('$(echo "$last_line" | sed "s/'/'\\\\''/g")')['session_id'])" 2>/dev/null || echo "?")
            turns=$(python3 -c "import json; print(json.loads('$(echo "$last_line" | sed "s/'/'\\\\''/g")')['turns'])" 2>/dev/null || echo "?")
            invoked=$(python3 -c "import json; print(json.loads('$(echo "$last_line" | sed "s/'/'\\\\''/g")')['skill_invoked_heuristic'])" 2>/dev/null || echo "?")
            echo "    session=$sess turns=$turns skill_invoked=$invoked"
        fi

        # Inter-trial delay
        if [[ $DELAY_MS -gt 0 ]]; then
            python3 -c "import time; time.sleep($DELAY_MS / 1000.0)"
        fi
    done < "$SHUFFLED_FILE"
done

elapsed=$(($(date +%s) - start_time))
total_lines=0
if [[ -f "$RESULTS_FILE" ]]; then
    total_lines=$(wc -l < "$RESULTS_FILE" | tr -d ' ')
fi
echo ""
echo "=== Runner complete: $VARIANT-$CONDITION ==="
echo "  Total lines in JSONL: $total_lines"
echo "  Completed this run: $completed_count, Errors: $error_count"
echo "  Elapsed: ${elapsed}s"
echo "  Output: $RESULTS_FILE"
