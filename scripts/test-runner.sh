#!/bin/bash
# test-runner.sh - Run P0 test cases against skills
# Usage: ./test-runner.sh path/to/skills/ test-cases.json [--compare-weights]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/score.sh" 2>/dev/null || true

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Parse JSON test cases (simple parser, no jq dependency)
parse_test_cases() {
    local json_file="$1"
    # Extract query and expected pairs
    grep -E '"query"|"expected"' "$json_file" | \
        sed 's/.*"query":[[:space:]]*"\([^"]*\)".*/QUERY:\1/' | \
        sed 's/.*"expected":[[:space:]]*"\([^"]*\)".*/EXPECTED:\1/'
}

# Get winner from scores output
get_winner() {
    local scores="$1"
    # First line is the winner (highest score)
    echo "$scores" | head -1 | cut -d: -f1
}

# Get score for a specific skill
get_score() {
    local scores="$1"
    local skill="$2"
    echo "$scores" | grep "^${skill}:" | cut -d: -f2
}

# Run a single test
run_test() {
    local query="$1"
    local expected="$2"
    local skills_dir="$3"

    # Get scores (non-verbose mode returns "skill:score" lines sorted by score desc)
    local scores=$(score_all_skills "$query" "$skills_dir" "false")

    local winner=$(get_winner "$scores")
    local winner_score=$(get_score "$scores" "$winner")
    local expected_score=$(get_score "$scores" "$expected")

    if [[ "$winner" == "$expected" ]]; then
        echo -e "${GREEN}✓${NC} \"$query\" → ${GREEN}$winner${NC} (rank #1, ${winner_score} pts)"
        return 0
    else
        echo -e "${RED}✗${NC} \"$query\" → expected ${YELLOW}$expected${NC}, got ${RED}$winner${NC}"
        echo -e "    Expected score: ${expected_score:-0} pts, Winner score: ${winner_score} pts"
        return 1
    fi
}

# Run all tests from JSON file
run_tests() {
    local skills_dir="$1"
    local test_file="$2"

    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}P0 Skill Activation Tests${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "Skills dir: ${CYAN}$skills_dir${NC}"
    echo -e "Test file:  ${CYAN}$test_file${NC}"
    echo ""
    echo -e "${YELLOW}Current weights:${NC}"
    echo "  WEIGHT_EXACT_NAME=$WEIGHT_EXACT_NAME"
    echo "  WEIGHT_KEYWORD_MATCH=$WEIGHT_KEYWORD_MATCH"
    echo "  WEIGHT_USE_WHEN=$WEIGHT_USE_WHEN"
    echo "  WEIGHT_STEM=$WEIGHT_STEM"
    echo "  WEIGHT_DESCRIPTION=$WEIGHT_DESCRIPTION"
    echo "  MIN_THRESHOLD=$MIN_THRESHOLD"
    echo ""
    echo -e "${BLUE}───────────────────────────────────────────────────────────────${NC}"
    echo ""

    local passed=0
    local total=0
    local query=""
    local expected=""

    # Read JSON file and extract test cases
    while IFS= read -r line; do
        if echo "$line" | grep -q '"query"'; then
            query=$(echo "$line" | sed 's/.*"query":[[:space:]]*"\([^"]*\)".*/\1/')
        elif echo "$line" | grep -q '"expected"'; then
            expected=$(echo "$line" | sed 's/.*"expected":[[:space:]]*"\([^"]*\)".*/\1/')

            if [[ -n "$query" && -n "$expected" ]]; then
                total=$((total + 1))
                if run_test "$query" "$expected" "$skills_dir"; then
                    passed=$((passed + 1))
                fi
                query=""
                expected=""
            fi
        fi
    done < "$test_file"

    echo ""
    echo -e "${BLUE}───────────────────────────────────────────────────────────────${NC}"

    local percent=0
    if [[ $total -gt 0 ]]; then
        percent=$((passed * 100 / total))
    fi

    if [[ $passed -eq $total ]]; then
        echo -e "${GREEN}Results: $passed/$total passed (${percent}%)${NC}"
    else
        echo -e "${YELLOW}Results: $passed/$total passed (${percent}%)${NC}"
    fi

    echo ""
    return $((total - passed))
}

# Compare different weight configurations
compare_weights() {
    local skills_dir="$1"
    local test_file="$2"

    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Weight Configuration Comparison${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    # Define weight configurations to test
    local configs=(
        "Default:10:10:3:3:1:5"
        "HighKeywords:10:15:3:3:1:5"
        "HighName:15:10:3:3:1:5"
        "HighUseWhen:10:10:5:3:1:5"
        "LowThreshold:10:10:3:3:1:3"
        "HighThreshold:10:10:3:3:1:7"
        "Balanced:8:8:4:4:2:5"
        "KeywordFocus:5:15:2:2:1:5"
    )

    local best_config=""
    local best_score=0

    for config in "${configs[@]}"; do
        IFS=':' read -r name exact keyword usewhen stem desc threshold <<< "$config"

        # Set weights
        export WEIGHT_EXACT_NAME=$exact
        export WEIGHT_KEYWORD_MATCH=$keyword
        export WEIGHT_USE_WHEN=$usewhen
        export WEIGHT_STEM=$stem
        export WEIGHT_DESCRIPTION=$desc
        export MIN_THRESHOLD=$threshold

        # Count passes silently
        local passed=0
        local total=0
        local query=""
        local expected=""

        while IFS= read -r line; do
            if echo "$line" | grep -q '"query"'; then
                query=$(echo "$line" | sed 's/.*"query":[[:space:]]*"\([^"]*\)".*/\1/')
            elif echo "$line" | grep -q '"expected"'; then
                expected=$(echo "$line" | sed 's/.*"expected":[[:space:]]*"\([^"]*\)".*/\1/')

                if [[ -n "$query" && -n "$expected" ]]; then
                    total=$((total + 1))
                    local scores=$(score_all_skills "$query" "$skills_dir" "false")
                    local winner=$(get_winner "$scores")
                    if [[ "$winner" == "$expected" ]]; then
                        passed=$((passed + 1))
                    fi
                    query=""
                    expected=""
                fi
            fi
        done < "$test_file"

        local percent=0
        if [[ $total -gt 0 ]]; then
            percent=$((passed * 100 / total))
        fi

        # Display result
        local color="$YELLOW"
        if [[ $passed -eq $total ]]; then
            color="$GREEN"
        elif [[ $percent -lt 50 ]]; then
            color="$RED"
        fi

        printf "%-15s %s%d/%d%s (%3d%%)  [name=%2d kw=%2d uw=%2d st=%2d desc=%d thr=%d]\n" \
            "$name:" "$color" "$passed" "$total" "$NC" "$percent" \
            "$exact" "$keyword" "$usewhen" "$stem" "$desc" "$threshold"

        if [[ $passed -gt $best_score ]]; then
            best_score=$passed
            best_config="$name"
        fi
    done

    echo ""
    echo -e "${BLUE}───────────────────────────────────────────────────────────────${NC}"
    echo -e "Best configuration: ${GREEN}$best_config${NC} ($best_score passed)"
    echo ""
}

# Show detailed breakdown for a single query
detailed_query() {
    local query="$1"
    local skills_dir="$2"

    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Detailed Scoring Breakdown${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    # Find all SKILL.md files and score each
    while IFS= read -r skill_file; do
        [[ -z "$skill_file" ]] && continue
        score_skill "$query" "$skill_file" "true"
        echo ""
    done < <(find "$skills_dir" -name "SKILL.md" -type f 2>/dev/null)
}

# Run embedded tests from each skill's test-cases.json
run_embedded_tests() {
    local skills_dir="$1"

    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}P0 Skill Activation Tests (Embedded)${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "Skills dir: ${CYAN}$skills_dir${NC}"
    echo ""
    echo -e "${YELLOW}Current weights:${NC}"
    echo "  WEIGHT_EXACT_NAME=$WEIGHT_EXACT_NAME"
    echo "  WEIGHT_KEYWORD_MATCH=$WEIGHT_KEYWORD_MATCH"
    echo "  WEIGHT_USE_WHEN=$WEIGHT_USE_WHEN"
    echo "  WEIGHT_STEM=$WEIGHT_STEM"
    echo "  WEIGHT_DESCRIPTION=$WEIGHT_DESCRIPTION"
    echo "  MIN_THRESHOLD=$MIN_THRESHOLD"
    echo ""

    local total_passed=0
    local total_tests=0

    # Find all skill directories with test-cases.json
    while IFS= read -r test_file; do
        [[ -z "$test_file" ]] && continue

        local skill_dir=$(dirname "$test_file")
        local skill_file="$skill_dir/SKILL.md"

        if [[ ! -f "$skill_file" ]]; then
            echo -e "${YELLOW}Warning: No SKILL.md found in $skill_dir${NC}"
            continue
        fi

        # Get skill name
        local skill_name=$(grep -i "^name:" "$skill_file" 2>/dev/null | sed 's/^name:[[:space:]]*//' | head -1)
        [[ -z "$skill_name" ]] && skill_name=$(basename "$skill_dir")

        echo -e "${BLUE}───────────────────────────────────────────────────────────────${NC}"
        echo -e "${CYAN}Skill: $skill_name${NC}"
        echo -e "Tests: $test_file"
        echo ""

        local passed=0
        local tests=0
        local query=""

        # Read test cases from the skill's test-cases.json
        while IFS= read -r line; do
            if echo "$line" | grep -q '"query"'; then
                query=$(echo "$line" | sed 's/.*"query":[[:space:]]*"\([^"]*\)".*/\1/')

                if [[ -n "$query" ]]; then
                    tests=$((tests + 1))
                    total_tests=$((total_tests + 1))

                    # Run test - expected is the current skill
                    if run_test "$query" "$skill_name" "$skills_dir"; then
                        passed=$((passed + 1))
                        total_passed=$((total_passed + 1))
                    fi
                    query=""
                fi
            fi
        done < "$test_file"

        local percent=0
        if [[ $tests -gt 0 ]]; then
            percent=$((passed * 100 / tests))
        fi

        if [[ $passed -eq $tests ]]; then
            echo -e "${GREEN}Skill result: $passed/$tests passed (${percent}%)${NC}"
        else
            echo -e "${YELLOW}Skill result: $passed/$tests passed (${percent}%)${NC}"
        fi
        echo ""

    done < <(find "$skills_dir" -name "test-cases.json" -type f 2>/dev/null | sort)

    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

    local total_percent=0
    if [[ $total_tests -gt 0 ]]; then
        total_percent=$((total_passed * 100 / total_tests))
    fi

    if [[ $total_passed -eq $total_tests ]]; then
        echo -e "${GREEN}TOTAL: $total_passed/$total_tests passed (${total_percent}%)${NC}"
    else
        echo -e "${YELLOW}TOTAL: $total_passed/$total_tests passed (${total_percent}%)${NC}"
    fi
    echo ""

    return $((total_tests - total_passed))
}

# Compare weights using embedded tests
compare_weights_embedded() {
    local skills_dir="$1"

    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Weight Configuration Comparison (Embedded Tests)${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    # Define weight configurations to test
    local configs=(
        "Default:10:10:3:3:1:5"
        "HighKeywords:10:15:3:3:1:5"
        "HighName:15:10:3:3:1:5"
        "HighUseWhen:10:10:5:3:1:5"
        "LowThreshold:10:10:3:3:1:3"
        "HighThreshold:10:10:3:3:1:7"
        "Balanced:8:8:4:4:2:5"
        "KeywordFocus:5:15:2:2:1:5"
    )

    local best_config=""
    local best_score=0
    local total_tests=0

    for config in "${configs[@]}"; do
        IFS=':' read -r name exact keyword usewhen stem desc threshold <<< "$config"

        # Set weights
        export WEIGHT_EXACT_NAME=$exact
        export WEIGHT_KEYWORD_MATCH=$keyword
        export WEIGHT_USE_WHEN=$usewhen
        export WEIGHT_STEM=$stem
        export WEIGHT_DESCRIPTION=$desc
        export MIN_THRESHOLD=$threshold

        local passed=0
        local tests=0

        # Find all skill directories with test-cases.json
        while IFS= read -r test_file; do
            [[ -z "$test_file" ]] && continue

            local skill_dir=$(dirname "$test_file")
            local skill_file="$skill_dir/SKILL.md"
            [[ ! -f "$skill_file" ]] && continue

            local skill_name=$(grep -i "^name:" "$skill_file" 2>/dev/null | sed 's/^name:[[:space:]]*//' | head -1)
            [[ -z "$skill_name" ]] && skill_name=$(basename "$skill_dir")

            local query=""
            while IFS= read -r line; do
                if echo "$line" | grep -q '"query"'; then
                    query=$(echo "$line" | sed 's/.*"query":[[:space:]]*"\([^"]*\)".*/\1/')

                    if [[ -n "$query" ]]; then
                        tests=$((tests + 1))
                        local scores=$(score_all_skills "$query" "$skills_dir" "false")
                        local winner=$(get_winner "$scores")
                        if [[ "$winner" == "$skill_name" ]]; then
                            passed=$((passed + 1))
                        fi
                        query=""
                    fi
                fi
            done < "$test_file"
        done < <(find "$skills_dir" -name "test-cases.json" -type f 2>/dev/null)

        total_tests=$tests

        local percent=0
        if [[ $tests -gt 0 ]]; then
            percent=$((passed * 100 / tests))
        fi

        local color="$YELLOW"
        if [[ $passed -eq $tests ]]; then
            color="$GREEN"
        elif [[ $percent -lt 50 ]]; then
            color="$RED"
        fi

        printf "%-15s %s%d/%d%s (%3d%%)  [name=%2d kw=%2d uw=%2d st=%2d desc=%d thr=%d]\n" \
            "$name:" "$color" "$passed" "$tests" "$NC" "$percent" \
            "$exact" "$keyword" "$usewhen" "$stem" "$desc" "$threshold"

        if [[ $passed -gt $best_score ]]; then
            best_score=$passed
            best_config="$name"
        fi
    done

    echo ""
    echo -e "${BLUE}───────────────────────────────────────────────────────────────${NC}"
    echo -e "Best configuration: ${GREEN}$best_config${NC} ($best_score/$total_tests passed)"
    echo ""
}

# Main
main() {
    local skills_dir="$1"
    local arg2="$2"
    local arg3="${3:-}"

    if [[ -z "$skills_dir" ]]; then
        echo "Usage: $0 path/to/skills/ [options]"
        echo ""
        echo "Modes:"
        echo "  $0 path/to/skills/                      Run embedded tests from each skill's test-cases.json"
        echo "  $0 path/to/skills/ test-cases.json      Run tests from external JSON file"
        echo ""
        echo "Options:"
        echo "  --compare-weights    Compare different weight configurations"
        echo "  --query \"text\"       Score a single query (detailed breakdown)"
        echo ""
        echo "Examples:"
        echo "  $0 ./sample-skills/                              # Run embedded tests"
        echo "  $0 ./sample-skills/ --compare-weights            # Compare weights with embedded tests"
        echo "  $0 ./sample-skills/ test-cases.json              # Run external test file"
        echo "  $0 ./sample-skills/ test-cases.json --compare    # Compare weights with external file"
        echo "  $0 ./sample-skills/ --query \"create component\"   # Score single query"
        exit 1
    fi

    if [[ ! -d "$skills_dir" ]]; then
        echo "Error: Skills directory not found: $skills_dir"
        exit 1
    fi

    # Handle --query mode
    if [[ "$arg2" == "--query" ]]; then
        local query="$arg3"
        if [[ -z "$query" ]]; then
            echo "Error: --query requires a query string"
            exit 1
        fi
        detailed_query "$query" "$skills_dir"
        exit 0
    fi

    # Handle --compare-weights with embedded tests (no external file)
    if [[ "$arg2" == "--compare-weights" || "$arg2" == "--compare" ]]; then
        compare_weights_embedded "$skills_dir"
        exit 0
    fi

    # Handle embedded tests (no external file specified)
    if [[ -z "$arg2" ]]; then
        run_embedded_tests "$skills_dir"
        exit $?
    fi

    # External test file mode
    local test_file="$arg2"
    local mode="$arg3"

    if [[ ! -f "$test_file" ]]; then
        echo "Error: Test file not found: $test_file"
        exit 1
    fi

    case "$mode" in
        --compare-weights|--compare)
            compare_weights "$skills_dir" "$test_file"
            ;;
        *)
            run_tests "$skills_dir" "$test_file"
            ;;
    esac
}

main "$@"
