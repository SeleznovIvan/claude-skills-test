#!/bin/bash
# run-experiment-v2.sh — Orchestrator for replication experiment
# Iterates all 12 conditions (3 variants × 4 conditions), configures filesystem, invokes runner.
#
# Usage:
#   ./run-experiment-v2.sh [--reps 10] [--resume] [--dry-run] [--seed 42] [--delay-ms 500] [--conditions "a-c1,c-c2,..."]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source directories for variant SKILL.md files
DESC_EXP_DIR="$PROJECT_ROOT/results/description-experiment"
VARIANT_A_DIR="$DESC_EXP_DIR/variant-a-current"
VARIANT_B_DIR="$DESC_EXP_DIR/variant-b-expanded"
VARIANT_C_DIR="$DESC_EXP_DIR/variant-c-directive"

# Target directories in the project
SKILLS_DIR="$PROJECT_ROOT/.claude/skills"
CLAUDE_MD="$PROJECT_ROOT/CLAUDE.md"
SETTINGS_JSON="$PROJECT_ROOT/.claude/settings.json"

# Source files for CLAUDE.md and settings.json
CLAUDE_MD_SOURCE="$DESC_EXP_DIR/CLAUDE.md"
SETTINGS_JSON_SOURCE="$DESC_EXP_DIR/settings.json"

# Data directory
DATA_DIR="$SCRIPT_DIR/data"

# Runner script
RUNNER="$SCRIPT_DIR/skill-test-runner-v2.sh"

# Skill names
SKILLS=("dockerfile-generator" "git-workflow" "svelte5-runes")

# Defaults
REPS=10
RESUME=false
DRY_RUN=false
SEED=42
DELAY_MS=500
CONDITIONS_FILTER=""
MAX_TURNS=5

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --reps)       REPS="$2"; shift 2 ;;
        --resume)     RESUME=true; shift ;;
        --dry-run)    DRY_RUN=true; shift ;;
        --seed)       SEED="$2"; shift 2 ;;
        --delay-ms)   DELAY_MS="$2"; shift 2 ;;
        --conditions) CONDITIONS_FILTER="$2"; shift 2 ;;
        --max-turns)  MAX_TURNS="$2"; shift 2 ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

echo "=============================================="
echo "=== Replication Experiment v2 Orchestrator ==="
echo "=============================================="
echo "  Reps: $REPS, Seed: $SEED, Max turns: $MAX_TURNS"
echo "  Resume: $RESUME, Dry-run: $DRY_RUN"
echo "  Delay: ${DELAY_MS}ms"
echo "  Conditions filter: ${CONDITIONS_FILTER:-all}"
echo "  Date: $(date)"
echo ""

# ---- Backup original files ----
BACKUP_DIR="$SCRIPT_DIR/.backup"
mkdir -p "$BACKUP_DIR"

backup_originals() {
    echo "[backup] Saving original files..."
    for skill in "${SKILLS[@]}"; do
        if [[ -f "$SKILLS_DIR/$skill/SKILL.md" ]]; then
            cp "$SKILLS_DIR/$skill/SKILL.md" "$BACKUP_DIR/${skill}-SKILL.md.orig"
        fi
    done
    if [[ -f "$CLAUDE_MD" ]]; then
        cp "$CLAUDE_MD" "$BACKUP_DIR/CLAUDE.md.orig"
        CLAUDE_MD_EXISTED=true
    else
        CLAUDE_MD_EXISTED=false
    fi
    if [[ -f "$SETTINGS_JSON" ]]; then
        cp "$SETTINGS_JSON" "$BACKUP_DIR/settings.json.orig"
        SETTINGS_JSON_EXISTED=true
    else
        SETTINGS_JSON_EXISTED=false
    fi
}

restore_originals() {
    echo ""
    echo "[restore] Restoring original files..."
    for skill in "${SKILLS[@]}"; do
        if [[ -f "$BACKUP_DIR/${skill}-SKILL.md.orig" ]]; then
            cp "$BACKUP_DIR/${skill}-SKILL.md.orig" "$SKILLS_DIR/$skill/SKILL.md"
        fi
    done
    if [[ "$CLAUDE_MD_EXISTED" == "true" ]]; then
        cp "$BACKUP_DIR/CLAUDE.md.orig" "$CLAUDE_MD"
    else
        rm -f "$CLAUDE_MD"
    fi
    if [[ "$SETTINGS_JSON_EXISTED" == "true" ]]; then
        cp "$BACKUP_DIR/settings.json.orig" "$SETTINGS_JSON"
    else
        rm -f "$SETTINGS_JSON"
    fi
    echo "[restore] Done."
}

# Restore on exit (including errors and signals)
trap restore_originals EXIT

backup_originals

# ---- Write frozen config ----
CONFIG_FILE="$DATA_DIR/config.json"
python3 -c "
import json
from datetime import datetime, timezone
config = {
    'experiment': 'replication-v2',
    'reps': $REPS,
    'seed': $SEED,
    'max_turns': $MAX_TURNS,
    'delay_ms': $DELAY_MS,
    'variants': ['a', 'b', 'c'],
    'conditions': ['c1', 'c2', 'c3', 'c4'],
    'condition_matrix': {
        'c1': {'claude_md': False, 'hook': False},
        'c2': {'claude_md': True,  'hook': False},
        'c3': {'claude_md': False, 'hook': True},
        'c4': {'claude_md': True,  'hook': True}
    },
    'variant_sources': {
        'a': '$VARIANT_A_DIR',
        'b': '$VARIANT_B_DIR',
        'c': '$VARIANT_C_DIR'
    },
    'skills': ['dockerfile-generator', 'git-workflow', 'svelte5-runes'],
    'queries_per_skill': 6,
    'total_queries': 18,
    'total_sessions': $REPS * 18 * 12,
    'started_at': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
}
with open('$CONFIG_FILE', 'w') as f:
    json.dump(config, f, indent=2)
print('Config written to $CONFIG_FILE')
"

# ---- Condition setup functions ----

setup_variant_skills() {
    local variant="$1"
    local src_dir=""
    case "$variant" in
        a) src_dir="$VARIANT_A_DIR" ;;
        b) src_dir="$VARIANT_B_DIR" ;;
        c) src_dir="$VARIANT_C_DIR" ;;
        *)
            echo "ERROR: Unknown variant '$variant'" >&2
            return 1
            ;;
    esac

    for skill in "${SKILLS[@]}"; do
        local src_file="$src_dir/${skill}-SKILL.md"
        local dst_file="$SKILLS_DIR/$skill/SKILL.md"
        if [[ ! -f "$src_file" ]]; then
            echo "ERROR: Missing variant file: $src_file" >&2
            return 1
        fi
        cp "$src_file" "$dst_file"
    done
}

setup_condition() {
    local cond="$1"
    case "$cond" in
        c1)
            # No CLAUDE.md, no hook
            rm -f "$CLAUDE_MD"
            rm -f "$SETTINGS_JSON"
            ;;
        c2)
            # CLAUDE.md present, no hook
            cp "$CLAUDE_MD_SOURCE" "$CLAUDE_MD"
            rm -f "$SETTINGS_JSON"
            ;;
        c3)
            # No CLAUDE.md, hook present
            rm -f "$CLAUDE_MD"
            cp "$SETTINGS_JSON_SOURCE" "$SETTINGS_JSON"
            ;;
        c4)
            # CLAUDE.md present, hook present
            cp "$CLAUDE_MD_SOURCE" "$CLAUDE_MD"
            cp "$SETTINGS_JSON_SOURCE" "$SETTINGS_JSON"
            ;;
        *)
            echo "ERROR: Unknown condition '$cond'" >&2
            return 1
            ;;
    esac
}

# ---- Build condition list ----
ALL_CONDITIONS=()
for v in a b c; do
    for c in c1 c2 c3 c4; do
        ALL_CONDITIONS+=("${v}-${c}")
    done
done

# Filter conditions if specified
RUN_CONDITIONS=()
if [[ -n "$CONDITIONS_FILTER" ]]; then
    IFS=',' read -ra FILTER_LIST <<< "$CONDITIONS_FILTER"
    for fc in "${FILTER_LIST[@]}"; do
        fc=$(echo "$fc" | tr -d ' ')
        # Validate
        found=false
        for ac in "${ALL_CONDITIONS[@]}"; do
            if [[ "$ac" == "$fc" ]]; then
                found=true
                break
            fi
        done
        if [[ "$found" == "false" ]]; then
            echo "ERROR: Unknown condition '$fc'. Valid: ${ALL_CONDITIONS[*]}" >&2
            exit 1
        fi
        RUN_CONDITIONS+=("$fc")
    done
else
    RUN_CONDITIONS=("${ALL_CONDITIONS[@]}")
fi

echo "Running ${#RUN_CONDITIONS[@]} conditions: ${RUN_CONDITIONS[*]}"
echo ""

# ---- Expected lines per condition ----
EXPECTED_LINES=$((18 * REPS))

# ---- Main loop ----
total_conditions=${#RUN_CONDITIONS[@]}
condition_num=0
experiment_start=$(date +%s)

for vc in "${RUN_CONDITIONS[@]}"; do
    condition_num=$((condition_num + 1))
    variant="${vc%%-*}"     # e.g., "a" from "a-c1"
    condition="${vc##*-}"   # e.g., "c1" from "a-c1"
    output_dir="$DATA_DIR/$vc"

    echo "========================================"
    echo "=== [$condition_num/$total_conditions] $vc (variant=$variant, condition=$condition) ==="
    echo "========================================"

    # Check if already complete (resume)
    if [[ "$RESUME" == "true" && -f "$output_dir/results.jsonl" ]]; then
        existing_lines=$(wc -l < "$output_dir/results.jsonl" | tr -d ' ')
        if [[ "$existing_lines" -ge "$EXPECTED_LINES" ]]; then
            echo "  SKIP: Already complete ($existing_lines/$EXPECTED_LINES lines)"
            echo ""
            continue
        fi
        echo "  RESUME: $existing_lines/$EXPECTED_LINES lines exist"
    fi

    # Setup filesystem for this condition
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "  [dry-run] Would setup:"
        echo "    Variant $variant: copy SKILL.md files from variant-${variant}-* dirs"
        case "$condition" in
            c1) echo "    Condition c1: remove CLAUDE.md, remove settings.json" ;;
            c2) echo "    Condition c2: install CLAUDE.md, remove settings.json" ;;
            c3) echo "    Condition c3: remove CLAUDE.md, install settings.json (hook)" ;;
            c4) echo "    Condition c4: install CLAUDE.md, install settings.json (hook)" ;;
        esac
        echo "  [dry-run] Would run:"
        echo "    $RUNNER --variant $variant --condition $condition --reps $REPS --max-turns $MAX_TURNS --output-dir $output_dir --seed $SEED --delay-ms $DELAY_MS"
        if [[ "$RESUME" == "true" ]]; then
            echo "    (with --resume)"
        fi
        echo ""
        continue
    fi

    # Configure filesystem
    setup_variant_skills "$variant"
    setup_condition "$condition"

    # Verify setup
    echo "  Files configured:"
    echo "    CLAUDE.md: $(test -f "$CLAUDE_MD" && echo 'present' || echo 'absent')"
    echo "    settings.json: $(test -f "$SETTINGS_JSON" && echo 'present' || echo 'absent')"
    for skill in "${SKILLS[@]}"; do
        echo "    $skill/SKILL.md: $(head -3 "$SKILLS_DIR/$skill/SKILL.md" | grep 'description:' | cut -c1-80)..."
    done
    echo ""

    # Build runner command
    RUNNER_CMD=("$RUNNER"
        --variant "$variant"
        --condition "$condition"
        --reps "$REPS"
        --max-turns "$MAX_TURNS"
        --output-dir "$output_dir"
        --seed "$SEED"
        --delay-ms "$DELAY_MS"
    )
    if [[ "$RESUME" == "true" ]]; then
        RUNNER_CMD+=(--resume)
    fi

    # Run
    cond_start=$(date +%s)
    "${RUNNER_CMD[@]}" 2>&1
    cond_elapsed=$(($(date +%s) - cond_start))

    # Verify output
    if [[ -f "$output_dir/results.jsonl" ]]; then
        result_lines=$(wc -l < "$output_dir/results.jsonl" | tr -d ' ')
        echo "  Result: $result_lines lines in $output_dir/results.jsonl"
    else
        echo "  WARNING: No results file created!"
    fi

    total_elapsed=$(($(date +%s) - experiment_start))
    echo "  Condition time: ${cond_elapsed}s | Total elapsed: ${total_elapsed}s"
    echo ""
done

# ---- Summary ----
echo "=============================================="
echo "=== Experiment Complete ==="
echo "=============================================="
echo "  Total elapsed: $(($(date +%s) - experiment_start))s"
echo ""
echo "  Results:"
for vc in "${RUN_CONDITIONS[@]}"; do
    output_dir="$DATA_DIR/$vc"
    if [[ -f "$output_dir/results.jsonl" ]]; then
        lines=$(wc -l < "$output_dir/results.jsonl" | tr -d ' ')
        echo "    $vc: $lines lines"
    else
        echo "    $vc: MISSING"
    fi
done
echo ""
echo "  Config: $CONFIG_FILE"
echo "  Data dir: $DATA_DIR"
