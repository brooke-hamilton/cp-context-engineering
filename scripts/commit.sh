#!/bin/bash

# ============================================================================
# Commit Script
#
# Stages all local changes and commits them with an AI-generated commit
# message using the Copilot CLI. The commit is signed off automatically.
#
# Usage: ./commit.sh [--dry-run]
#
# Options:
#   --dry-run  Generate the commit message and print the git commit command
#              to the terminal, but do not execute it.
# ============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Global variables
# ---------------------------------------------------------------------------
readonly COPILOT_MODEL="gpt-5.3-codex"

SEPARATOR=$(printf '=%.0s' {1..76})
readonly SEPARATOR

DIFF_STAT=""
FULL_DIFF=""
COMMIT_MESSAGE=""

declare -a TEMP_FILES=()
DRY_RUN=false

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------
cleanup() {
    for f in "${TEMP_FILES[@]}"; do
        if [[ -f "${f}" ]]; then
            rm --force "${f}"
        fi
    done
}

trap cleanup EXIT

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

    if [[ -z "$(git status --porcelain)" ]]; then
        echo "ERROR: No changes detected." \
            "Nothing to commit." >&2
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# validate_branch
# ---------------------------------------------------------------------------
validate_branch() {
    local current_branch
    current_branch=$(git branch --show-current)

    # Detect default branch from remote HEAD; fall back to
    # matching "main" or "master" when the remote is unknown.
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

    if [[ "${on_default}" == true ]]; then
        echo "  WARNING: Currently on default branch" \
            "'${current_branch}'."
        echo "  Direct commits to the default branch" \
            "are not allowed."
        echo ""

        if [[ ! -t 0 ]]; then
            echo "ERROR: Cannot prompt for branch" \
                "name — stdin is not a terminal." >&2
            exit 1
        fi

        local new_branch=""
        read -rp "  Enter a new branch name: " new_branch

        if [[ -z "${new_branch}" ]]; then
            echo "ERROR: Branch name cannot be empty." >&2
            exit 1
        fi

        if ! git check-ref-format --branch "${new_branch}" \
            >/dev/null 2>&1; then
            echo "ERROR: '${new_branch}' is not a valid" \
                "branch name." >&2
            exit 1
        fi

        git checkout -b "${new_branch}"
        echo "  ✓ Created and switched to branch" \
            "'${new_branch}'"
    fi
}

# ---------------------------------------------------------------------------
# stage_changes
# ---------------------------------------------------------------------------
stage_changes() {
    echo "Staging all changes..."

    git add --all
    echo "  ✓ All changes staged"
}

# ---------------------------------------------------------------------------
# gather_diff_context
# ---------------------------------------------------------------------------
gather_diff_context() {
    echo "Gathering diff context..."

    DIFF_STAT=$(git diff HEAD --stat)
    FULL_DIFF=$(git diff HEAD)

    local file_count
    file_count=$(echo "${DIFF_STAT}" | grep --count '|' || true)
    echo "  ✓ Diff stat: ${file_count} file(s) changed"
}

# ---------------------------------------------------------------------------
# generate_commit_message
# ---------------------------------------------------------------------------
generate_commit_message() {
    echo "Generating commit message via Copilot CLI..."

    local prompt
    prompt="Generate a git commit message subject line for the following staged changes.

RULES FOR OUTPUT FORMAT:
- Line 1: The commit subject line (plain text only)
- NO other output besides the subject line. No responses or commentary. Just the commit subject line.

RULES FOR THE SUBJECT LINE:
- The subject should be a noun (or compound noun) optionally prefixed with adjectives. 
- Other noun modifying phrases can be added, like prepositional phrases, participle phrases, and infinitive phrases, i.e., the overall subject should be a noun plus descriptives.
- The first word in the subject should begin with a capital letter. Do not start the subject with a verb like Add or Update. 
- The only capitalized word in the subject should be the first word. The rest of the subject should be lowercase.
- Maximum 50 characters
- First word capitalized
- No trailing period
- No conventional commit prefixes (no fix:, feat:, chore:, etc.)

DIFF STAT:
${DIFF_STAT}

FULL DIFF:
${FULL_DIFF}"

    local copilot_output
    copilot_output=$(printf '%s\n' "${prompt}" \
        | copilot --silent --model "${COPILOT_MODEL}") || {
        echo "ERROR: Copilot CLI invocation failed." >&2
        exit 1
    }

    COMMIT_MESSAGE=$(printf '%s\n' "${copilot_output}" | head --lines=1)

    if [[ -z "${COMMIT_MESSAGE}" ]]; then
        echo "ERROR: Copilot CLI returned an empty" \
            "commit message." >&2
        exit 1
    fi

    local subject
    subject=$(printf '%s\n' "${COMMIT_MESSAGE}" | head --lines=1)
    echo "  ✓ Message generated"
    echo "  Subject: ${subject}"
}

# ---------------------------------------------------------------------------
# do_commit
# ---------------------------------------------------------------------------
do_commit() {
    echo "Committing changes..."

    local msg_file
    msg_file=$(mktemp)
    TEMP_FILES+=("${msg_file}")
    printf '%s\n' "${COMMIT_MESSAGE}" > "${msg_file}"

    git commit --signoff --file="${msg_file}" || {
        echo "ERROR: git commit failed." >&2
        exit 1
    }

    echo "  ✓ Changes committed"
}

# ---------------------------------------------------------------------------
# print_dry_run
# ---------------------------------------------------------------------------
print_dry_run() {
    # Escape single quotes for safe use in a shell command:
    # replaces ' with '\'' (close quote, escaped quote, reopen quote)
    local msg_escaped
    msg_escaped=$(printf '%s' "${COMMIT_MESSAGE}" \
        | sed "s/'/'\\\\''/g")

    echo "${SEPARATOR}"
    echo "DRY RUN — No changes were staged or committed"
    echo "${SEPARATOR}"
    echo ""
    echo "Commit message:"
    echo "${COMMIT_MESSAGE}"
    echo ""
    echo "${SEPARATOR}"
    echo "To commit manually, run:"
    echo ""
    echo "  git commit --signoff --message='${msg_escaped}'"
    echo "${SEPARATOR}"
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
    validate_prerequisites
    validate_preconditions
    validate_branch
    gather_diff_context
    generate_commit_message

    if [[ "${DRY_RUN}" == true ]]; then
        print_dry_run
    else
        stage_changes
        do_commit
    fi
}

# ---------------------------------------------------------------------------
# usage
# ---------------------------------------------------------------------------
usage() {
    echo "Usage: $(basename "$0") [OPTIONS]"
    echo "Options:"
    echo "  --dry-run  Generate commit message but do not commit"
    echo "  --help     Show this help"
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help)
            usage
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

main
