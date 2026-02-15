#!/bin/bash

# ============================================================================
# Branch Script
#
# Detects uncommitted, staged, or untracked changes in the local workspace
# and uses the Copilot CLI to generate a descriptive branch name, then
# creates and switches to that branch.
#
# Usage: ./branch.sh
# ============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Global variables
# ---------------------------------------------------------------------------
readonly COPILOT_MODEL="gpt-5.3-codex"

DIFF_STAT=""
FULL_DIFF=""
UNTRACKED_FILES=""
BRANCH_NAME=""

# ---------------------------------------------------------------------------
# validate_prerequisites
# ---------------------------------------------------------------------------
validate_prerequisites() {
    if ! command -v git >/dev/null; then
        echo "ERROR: git is not installed." >&2
        exit 1
    fi

    if ! command -v copilot >/dev/null; then
        echo "ERROR: Copilot CLI (copilot) is not found on PATH." \
            "See installation docs." >&2
        exit 1
    fi

    if ! copilot --version >/dev/null; then
        echo "ERROR: Copilot CLI is not functional." \
            "Check authentication." >&2
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# validate_preconditions
# ---------------------------------------------------------------------------
validate_preconditions() {
    if ! git rev-parse --is-inside-work-tree >/dev/null; then
        echo "ERROR: Not inside a git repository." >&2
        exit 1
    fi

    # Must be on the default branch
    local current_branch
    current_branch=$(git branch --show-current)

    local default_branch=""
    if git rev-parse --verify refs/remotes/origin/HEAD \
        >/dev/null 2>&1; then
        default_branch=$(git symbolic-ref \
            refs/remotes/origin/HEAD \
            | sed 's|refs/remotes/origin/||')
    fi

    local on_default=false
    if [[ -n "${default_branch}" ]]; then
        if [[ "${current_branch}" == "${default_branch}" ]]; then
            on_default=true
        fi
    else
        if [[ "${current_branch}" == "main" \
            || "${current_branch}" == "master" ]]; then
            on_default=true
        fi
    fi

    if [[ "${on_default}" != true ]]; then
        echo "ERROR: Not on the default branch." \
            "Currently on '${current_branch}'." \
            "This script should only be run from the" \
            "default branch." >&2
        exit 1
    fi

    # Must have uncommitted, staged, or untracked changes
    if [[ -z "$(git status --porcelain)" ]]; then
        echo "ERROR: No changes detected." \
            "Nothing to create a branch for." >&2
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# gather_diff_context
# ---------------------------------------------------------------------------
gather_diff_context() {
    echo "Gathering diff context..."

    DIFF_STAT=$(git diff --stat HEAD 2>/dev/null || true)
    FULL_DIFF=$(git diff HEAD 2>/dev/null || true)

    # Include staged changes that may not appear in diff HEAD
    local staged_diff
    staged_diff=$(git diff --cached --stat 2>/dev/null || true)
    if [[ -n "${staged_diff}" ]]; then
        DIFF_STAT="${DIFF_STAT}
${staged_diff}"
    fi

    UNTRACKED_FILES=$(git ls-files --others --exclude-standard)

    local file_count
    file_count=$(echo "${DIFF_STAT}" | grep --count '|' || true)
    echo "  ✓ Diff stat: ${file_count} file(s) changed"

    if [[ -n "${UNTRACKED_FILES}" ]]; then
        local untracked_count
        untracked_count=$(echo "${UNTRACKED_FILES}" | wc -l \
            | tr -d ' ')
        echo "  ✓ Untracked files: ${untracked_count}"
    fi
}

# ---------------------------------------------------------------------------
# generate_branch_name
# ---------------------------------------------------------------------------
generate_branch_name() {
    echo "Generating branch name via Copilot CLI..."

    local prompt
    prompt="Generate a git branch name for the following local changes.

RULES FOR OUTPUT FORMAT:
- Output ONLY the branch name. No other text, no explanation, no commentary.

RULES FOR THE BRANCH NAME:
- Use lowercase letters, numbers, and hyphens only
- No slashes, underscores, or special characters
- Maximum 25 characters
- Should be a concise, descriptive name summarizing the changes
- Do NOT include prefixes like feature/, fix/, chore/, etc.

DIFF STAT:
${DIFF_STAT}

UNTRACKED FILES:
${UNTRACKED_FILES}

FULL DIFF:
${FULL_DIFF}"

    local copilot_output
    copilot_output=$(printf '%s\n' "${prompt}" \
        | copilot --silent --model "${COPILOT_MODEL}") || {
        echo "ERROR: Copilot CLI invocation failed." >&2
        exit 1
    }

    BRANCH_NAME=$(printf '%s\n' "${copilot_output}" \
        | head --lines=1 \
        | tr -d '[:space:]')

    if [[ -z "${BRANCH_NAME}" ]]; then
        echo "ERROR: Copilot CLI returned an empty" \
            "branch name." >&2
        exit 1
    fi

    if ! git check-ref-format --branch "${BRANCH_NAME}" \
        >/dev/null 2>&1; then
        echo "ERROR: Generated branch name" \
            "'${BRANCH_NAME}' is not a valid" \
            "git branch name." >&2
        exit 1
    fi

    echo "  ✓ Branch name generated: ${BRANCH_NAME}"
}

# ---------------------------------------------------------------------------
# create_branch
# ---------------------------------------------------------------------------
create_branch() {
    echo "Creating branch..."

    git checkout -b "${BRANCH_NAME}"
    echo "  ✓ Created and switched to branch '${BRANCH_NAME}'"
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
    validate_prerequisites
    validate_preconditions
    gather_diff_context
    generate_branch_name
    create_branch
}

main
