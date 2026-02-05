#!/bin/bash
# score.sh - Skill activation scoring algorithm
# Usage: ./score.sh "query" path/to/skills/

set -e

# Default weights (can be tuned via environment variables)
WEIGHT_EXACT_NAME=${WEIGHT_EXACT_NAME:-10}      # Skill name appears in query
WEIGHT_KEYWORD_MATCH=${WEIGHT_KEYWORD_MATCH:-10} # Explicit keyword match
WEIGHT_USE_WHEN=${WEIGHT_USE_WHEN:-3}           # "Use when" trigger phrase match
WEIGHT_STEM=${WEIGHT_STEM:-3}                   # Stem variation match
WEIGHT_DESCRIPTION=${WEIGHT_DESCRIPTION:-1}     # General description word match
MIN_THRESHOLD=${MIN_THRESHOLD:-5}               # Minimum score to activate

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Stemmer - removes one suffix (longest match first) + doubled consonant fix
stem_word() {
    local word="$1"
    word=$(echo "$word" | tr '[:upper:]' '[:lower:]')
    local dedup=false
    # Try longest suffixes first, stop after first match
    # Suffixes that cause consonant doubling (running→runn, stopped→stopp) set dedup=true
    if [[ "$word" == *izing ]]; then word="${word%izing}"
    elif [[ "$word" == *ising ]]; then word="${word%ising}"
    elif [[ "$word" == *ment ]]; then word="${word%ment}"
    elif [[ "$word" == *ness ]]; then word="${word%ness}"
    elif [[ "$word" == *able ]]; then word="${word%able}"
    elif [[ "$word" == *ible ]]; then word="${word%ible}"
    elif [[ "$word" == *tion ]]; then word="${word%tion}"
    elif [[ "$word" == *sion ]]; then word="${word%sion}"
    elif [[ "$word" == *less ]]; then word="${word%less}"
    elif [[ "$word" == *ful ]]; then word="${word%ful}"
    elif [[ "$word" == *ous ]]; then word="${word%ous}"
    elif [[ "$word" == *ive ]]; then word="${word%ive}"
    elif [[ "$word" == *ing ]]; then word="${word%ing}"; dedup=true
    elif [[ "$word" == *ize ]]; then word="${word%ize}"
    elif [[ "$word" == *ise ]]; then word="${word%ise}"
    elif [[ "$word" == *ed ]]; then word="${word%ed}"; dedup=true
    elif [[ "$word" == *ly ]]; then word="${word%ly}"
    elif [[ "$word" == *al ]]; then word="${word%al}"
    elif [[ "$word" == *er ]]; then word="${word%er}"; dedup=true
    elif [[ "$word" == *es ]]; then word="${word%es}"
    elif [[ "$word" == *s ]]; then word="${word%s}"
    fi
    # Only fix doubled consonants after suffixes that cause doubling (-ing, -ed, -er)
    if [[ "$dedup" == true && ${#word} -ge 3 && "${word: -1}" == "${word: -2:1}" ]]; then
        word="${word%?}"
    fi
    echo "$word"
}

# Extract field from SKILL.md
extract_field() {
    local file="$1"
    local field="$2"
    grep -i "^${field}:" "$file" 2>/dev/null | sed "s/^${field}:[[:space:]]*//" | head -1
}

# Extract "Use when" triggers from description
extract_use_when() {
    local file="$1"
    # Look for "Use when" or "use this when" patterns in description
    grep -i "use.*when\|use this.*for\|activate.*when" "$file" 2>/dev/null | \
        sed 's/.*[Uu]se.*when[[:space:]]*//' | \
        sed 's/.*[Uu]se this.*for[[:space:]]*//' | \
        tr ',' '\n' | tr ' ' '\n' | \
        grep -v '^$' | sort -u
}

# Extract keywords from SKILL.md (comma-separated, supports multi-word phrases)
extract_keywords() {
    local file="$1"
    local keywords_line=$(grep -i "^keywords:" "$file" 2>/dev/null | sed 's/^keywords:[[:space:]]*//')
    if [[ -n "$keywords_line" ]]; then
        echo "$keywords_line" | tr ',' '\n' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//' | grep -v '^$'
    fi
}

# Score a single skill against a query
score_skill() {
    local query="$1"
    local skill_file="$2"
    local verbose="${3:-false}"

    local total_score=0
    local breakdown=""

    # Normalize query
    local query_lower=$(echo "$query" | tr '[:upper:]' '[:lower:]')
    local query_words=$(echo "$query_lower" | tr -cs '[:alnum:]$' '\n' | grep -v '^$')

    # Get skill metadata
    local skill_name=$(extract_field "$skill_file" "name")
    local skill_desc=$(extract_field "$skill_file" "description" | tr '[:upper:]' '[:lower:]')
    local skill_keywords=$(extract_keywords "$skill_file")

    # 1. Check exact name match
    local name_lower=$(echo "$skill_name" | tr '[:upper:]' '[:lower:]')
    local name_no_dash=$(echo "$name_lower" | tr '-' ' ')

    if echo "$query_lower" | grep -q "$name_lower"; then
        total_score=$((total_score + WEIGHT_EXACT_NAME))
        breakdown="${breakdown}  +${WEIGHT_EXACT_NAME}  exact-name: ${skill_name}\n"
    elif echo "$query_lower" | grep -q "$name_no_dash"; then
        total_score=$((total_score + WEIGHT_EXACT_NAME))
        breakdown="${breakdown}  +${WEIGHT_EXACT_NAME}  exact-name: ${name_no_dash}\n"
    fi

    # 2. Check keyword matches
    if [[ -n "$skill_keywords" ]]; then
        while IFS= read -r keyword; do
            keyword=$(echo "$keyword" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
            [[ -z "$keyword" ]] && continue
            if echo "$query_lower" | grep -qi "\b${keyword}\b" 2>/dev/null || echo "$query_lower" | grep -qi "${keyword}"; then
                total_score=$((total_score + WEIGHT_KEYWORD_MATCH))
                breakdown="${breakdown}  +${WEIGHT_KEYWORD_MATCH}  keyword: ${keyword}\n"
            fi
        done <<< "$skill_keywords"
    fi

    # 3. Check "Use when" trigger matches
    local use_when_triggers=$(extract_use_when "$skill_file")
    if [[ -n "$use_when_triggers" ]]; then
        while IFS= read -r trigger; do
            trigger=$(echo "$trigger" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
            [[ -z "$trigger" || ${#trigger} -lt 3 ]] && continue
            if echo "$query_lower" | grep -qi "$trigger"; then
                total_score=$((total_score + WEIGHT_USE_WHEN))
                breakdown="${breakdown}  +${WEIGHT_USE_WHEN}  use-when: ${trigger}\n"
            fi
        done <<< "$use_when_triggers"
    fi

    # 4. Check stem matches between query and description
    local desc_words=$(echo "$skill_desc" | tr -cs '[:alnum:]' '\n' | grep -v '^$')
    while IFS= read -r qword; do
        [[ -z "$qword" || ${#qword} -lt 3 ]] && continue
        local qstem=$(stem_word "$qword")
        [[ ${#qstem} -lt 3 ]] && continue

        while IFS= read -r dword; do
            [[ -z "$dword" || ${#dword} -lt 3 ]] && continue
            local dstem=$(stem_word "$dword")
            [[ ${#dstem} -lt 3 ]] && continue

            if [[ "$qstem" == "$dstem" && "$qword" != "$dword" ]]; then
                total_score=$((total_score + WEIGHT_STEM))
                breakdown="${breakdown}  +${WEIGHT_STEM}  stem: ${qword}→${dword}\n"
                break
            fi
        done <<< "$desc_words"
    done <<< "$query_words"

    # 5. Check description word matches
    while IFS= read -r qword; do
        [[ -z "$qword" || ${#qword} -lt 4 ]] && continue
        if echo "$skill_desc" | grep -qi "\b${qword}\b" 2>/dev/null || echo "$skill_desc" | grep -qi "$qword"; then
            total_score=$((total_score + WEIGHT_DESCRIPTION))
            breakdown="${breakdown}  +${WEIGHT_DESCRIPTION}  description: ${qword}\n"
        fi
    done <<< "$query_words"

    # Output result
    local status_color="$RED"
    local status="FAIL"
    if [[ $total_score -ge $MIN_THRESHOLD ]]; then
        status_color="$GREEN"
        status="PASS"
    fi

    if [[ "$verbose" == "true" ]]; then
        echo -e "${skill_name}: ${YELLOW}${total_score}${NC} pts [${status_color}${status}${NC} - threshold ${MIN_THRESHOLD}]"
        if [[ -n "$breakdown" ]]; then
            echo -e "$breakdown"
        fi
    else
        echo "${skill_name}:${total_score}"
    fi
}

# Score all skills in a directory
score_all_skills() {
    local query="$1"
    local skills_dir="$2"
    local verbose="${3:-false}"

    local results=""

    # Find all SKILL.md files
    while IFS= read -r skill_file; do
        [[ -z "$skill_file" ]] && continue
        local result=$(score_skill "$query" "$skill_file" "$verbose")
        if [[ "$verbose" == "true" ]]; then
            echo "$result"
            echo ""
        else
            results="${results}${result}\n"
        fi
    done < <(find "$skills_dir" -name "SKILL.md" -type f 2>/dev/null)

    if [[ "$verbose" != "true" && -n "$results" ]]; then
        # Sort by score descending and output
        echo -e "$results" | grep -v '^$' | sort -t: -k2 -rn
    fi
}

# Main
main() {
    local query="$1"
    local skills_dir="$2"
    local verbose="${3:-}"

    if [[ -z "$query" || -z "$skills_dir" ]]; then
        echo "Usage: $0 \"query\" path/to/skills/ [--verbose]"
        echo ""
        echo "Environment variables for weight tuning:"
        echo "  WEIGHT_EXACT_NAME=$WEIGHT_EXACT_NAME"
        echo "  WEIGHT_KEYWORD_MATCH=$WEIGHT_KEYWORD_MATCH"
        echo "  WEIGHT_USE_WHEN=$WEIGHT_USE_WHEN"
        echo "  WEIGHT_STEM=$WEIGHT_STEM"
        echo "  WEIGHT_DESCRIPTION=$WEIGHT_DESCRIPTION"
        echo "  MIN_THRESHOLD=$MIN_THRESHOLD"
        exit 1
    fi

    if [[ ! -d "$skills_dir" ]]; then
        echo "Error: Skills directory not found: $skills_dir"
        exit 1
    fi

    local is_verbose="false"
    if [[ "$verbose" == "--verbose" || "$verbose" == "-v" ]]; then
        is_verbose="true"
    fi

    echo -e "${BLUE}Query:${NC} \"$query\""
    echo -e "${BLUE}Skills dir:${NC} $skills_dir"
    echo ""

    score_all_skills "$query" "$skills_dir" "$is_verbose"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
