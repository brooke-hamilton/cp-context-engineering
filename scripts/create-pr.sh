#!/bin/bash

# ============================================================================
# PR Creation Script
#
# Creates a GitHub pull request with an AI-generated title and description
# using the Copilot CLI. Auto-detects fork configuration, validates
# pre-conditions, and creates the PR via the GitHub CLI.
#
# Usage: ./create-pr.sh [--dry-run]
#
# Options:
#   --dry-run  Do everything except create the PR. Outputs the generated
#              title and description to the terminal.
# ============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Global variables
# ---------------------------------------------------------------------------
readonly COPILOT_MODEL="gpt-5.3-codex"

CURRENT_BRANCH=""
DEFAULT_BRANCH=""
MAIN_REMOTE=""
MAIN_REPO=""
BRANCH_REMOTE=""

SEPARATOR=$(printf '=%.0s' {1..76})
readonly SEPARATOR

DIFF_STAT=""
FULL_DIFF=""
COMMIT_LOG=""
PR_TEMPLATE=""
TEMPLATE_PATH=""

PR_TITLE=""
PR_DESCRIPTION=""
PR_URL=""

TEMP_FILES=()
DRY_RUN=false

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------
cleanup() {
    for f in "${TEMP_FILES[@]}"; do
        if [[ -f "${f}" ]]; then
            rm -f "${f}"
        fi
    done
}

trap cleanup EXIT

# ---------------------------------------------------------------------------
# validate_prerequisites
# ---------------------------------------------------------------------------
validate_prerequisites() {
    echo "Checking prerequisites..."

    if ! command -v git &>/dev/null; then
        echo "ERROR: git is not installed." >&2
        exit 1
    fi
    echo "  ✓ git is available"

    if ! command -v gh &>/dev/null; then
        echo "ERROR: GitHub CLI (gh) is not installed." \
            "Install from https://cli.github.com" >&2
        exit 1
    fi

    if ! gh auth status >/dev/null 2>&1; then
        echo "ERROR: Not authenticated to GitHub CLI." \
            "Run 'gh auth login'." >&2
        exit 1
    fi
    echo "  ✓ GitHub CLI (gh) is authenticated"

    if ! command -v copilot &>/dev/null; then
        echo "ERROR: Copilot CLI (copilot) is not found on PATH." \
            "See installation docs." >&2
        exit 1
    fi

    if ! copilot --version &>/dev/null; then
        echo "ERROR: Copilot CLI is not functional." \
            "Check authentication." >&2
        exit 1
    fi
    echo "  ✓ Copilot CLI (copilot) is available"
}

# ---------------------------------------------------------------------------
# get_remote_owner
# ---------------------------------------------------------------------------
get_remote_owner() {
    local remote_url
    remote_url=$(git remote get-url "$1")
    printf '%s\n' "${remote_url}" \
        | sed -E 's|.*[:/]([^/]+)/[^/]+(.git)?$|\1|'
}

# ---------------------------------------------------------------------------
# detect_remote_config
# ---------------------------------------------------------------------------
detect_remote_config() {
    echo "Detecting remote configuration..."

    if git remote get-url upstream &>/dev/null; then
        MAIN_REMOTE="upstream"
        echo "  Remote setup: upstream remote found"
    else
        MAIN_REMOTE="origin"
        echo "  Remote setup: using origin"
    fi

    echo "  Main remote: ${MAIN_REMOTE}"
}

# ---------------------------------------------------------------------------
# determine_default_branch
# ---------------------------------------------------------------------------
determine_default_branch() {
    echo "Determining default branch..."

    DEFAULT_BRANCH=$(
        git symbolic-ref "refs/remotes/${MAIN_REMOTE}/HEAD" \
            2>/dev/null \
        | sed "s@^refs/remotes/${MAIN_REMOTE}/@@"
    ) || true

    if [[ -z "${DEFAULT_BRANCH}" ]]; then
        git remote set-head "${MAIN_REMOTE}" --auto >/dev/null 2>&1
        DEFAULT_BRANCH=$(
            git symbolic-ref "refs/remotes/${MAIN_REMOTE}/HEAD" \
            | sed "s@^refs/remotes/${MAIN_REMOTE}/@@"
        ) || true
    fi

    if [[ -z "${DEFAULT_BRANCH}" ]]; then
        echo "ERROR: Cannot determine the default branch" \
            "for remote '${MAIN_REMOTE}'." >&2
        exit 1
    fi

    echo "  Default branch: ${DEFAULT_BRANCH}"
}

# ---------------------------------------------------------------------------
# validate_preconditions
# ---------------------------------------------------------------------------
validate_preconditions() {
    echo "Validating pre-conditions..."

    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

    # 1. Not on default branch
    if [[ "${CURRENT_BRANCH}" == "${DEFAULT_BRANCH}" ]]; then
        echo "ERROR: Cannot create PR from the default branch" \
            "'${DEFAULT_BRANCH}'. Switch to a feature branch." >&2
        exit 1
    fi
    echo "  ✓ On feature branch '${CURRENT_BRANCH}'"

    # 2. Clean working directory
    if [[ -n "$(git status --porcelain)" ]]; then
        echo "ERROR: Uncommitted changes detected. Commit or" \
            "stash your changes before creating a PR." >&2
        exit 1
    fi
    echo "  ✓ Working directory is clean"

    # 3. Commits ahead of default branch
    local count
    count=$(git rev-list --count \
        "${MAIN_REMOTE}/${DEFAULT_BRANCH}..HEAD")
    if [[ "${count}" -eq 0 ]]; then
        echo "ERROR: No commits ahead of '${DEFAULT_BRANCH}'." \
            "Nothing to create a PR for." >&2
        exit 1
    fi
    echo "  ✓ ${count} commit(s) ahead of '${DEFAULT_BRANCH}'"

    # 4. Branch pushed to at least one remote
    local -a found_remotes=()
    local -A remote_shas=()
    local sha=""
    while IFS= read -r remote; do
        sha=$(
            git ls-remote --heads "${remote}" \
                "${CURRENT_BRANCH}" 2>/dev/null \
            | awk '{print $1}'
        )
        if [[ -n "${sha}" ]]; then
            found_remotes+=("${remote}")
            remote_shas["${remote}"]="${sha}"
        fi
    done < <(git remote)

    if [[ ${#found_remotes[@]} -eq 0 ]]; then
        echo "ERROR: Branch '${CURRENT_BRANCH}' has not" \
            "been pushed to any remote." \
            "Run 'git push' first." >&2
        exit 1
    fi

    if [[ ${#found_remotes[@]} -eq 1 ]]; then
        BRANCH_REMOTE="${found_remotes[0]}"
    else
        echo "  Branch '${CURRENT_BRANCH}' exists on" \
            "multiple remotes:"
        local i
        for i in "${!found_remotes[@]}"; do
            echo "    $((i + 1))) ${found_remotes[${i}]}"
        done
        local selection
        while true; do
            read -rp "  Select remote for the PR [1-${#found_remotes[@]}]: " \
                selection
            if [[ "${selection}" =~ ^[0-9]+$ ]] \
                && (( selection >= 1 )) \
                && (( selection <= ${#found_remotes[@]} )); then
                BRANCH_REMOTE="${found_remotes[$((selection - 1))]}"
                break
            fi
            echo "  Invalid selection. Try again."
        done
    fi

    local local_sha
    local_sha=$(git rev-parse HEAD)
    if [[ "${local_sha}" != "${remote_shas[${BRANCH_REMOTE}]}" ]]; then
        echo "ERROR: Branch '${CURRENT_BRANCH}' has" \
            "unpushed commits on '${BRANCH_REMOTE}'." \
            "Run 'git push' first." >&2
        exit 1
    fi
    echo "  ✓ Branch pushed to '${BRANCH_REMOTE}'"

    # 5. No existing PR
    local pr_head="${CURRENT_BRANCH}"
    if [[ "${BRANCH_REMOTE}" != "${MAIN_REMOTE}" ]]; then
        local branch_owner
        branch_owner=$(get_remote_owner "${BRANCH_REMOTE}")
        pr_head="${branch_owner}:${CURRENT_BRANCH}"
    fi
    local pr_check_repo=""
    local main_url
    main_url=$(git remote get-url "${MAIN_REMOTE}")
    pr_check_repo=$(printf '%s\n' "${main_url}" \
        | sed -E 's|.*[:/]([^/]+/[^/]+?)(.git)?$|\1|')
    local existing_url
    existing_url=$(
        gh pr list --head "${pr_head}" \
            --repo "${pr_check_repo}" \
            --json url --jq '.[0].url' 2>/dev/null
    ) || true
    if [[ -n "${existing_url}" ]]; then
        echo "ERROR: A PR already exists for branch" \
            "'${CURRENT_BRANCH}': ${existing_url}" >&2
        exit 1
    fi
    echo "  ✓ No existing PR for this branch"
}

# ---------------------------------------------------------------------------
# fetch_default_branch
# ---------------------------------------------------------------------------
fetch_default_branch() {
    echo "Fetching latest '${DEFAULT_BRANCH}'" \
        "from '${MAIN_REMOTE}'..."

    if ! git fetch "${MAIN_REMOTE}" "${DEFAULT_BRANCH}" \
        >/dev/null; then
        echo "ERROR: Failed to fetch '${DEFAULT_BRANCH}'" \
            "from '${MAIN_REMOTE}'." >&2
        exit 1
    fi
    echo "  ✓ Fetch complete"
}

# ---------------------------------------------------------------------------
# find_pr_template
# ---------------------------------------------------------------------------
find_pr_template() {
    local repo_root
    repo_root=$(git rev-parse --show-toplevel)
    local locations=(
        ".github/PULL_REQUEST_TEMPLATE.md"
        ".github/pull_request_template.md"
        "docs/PULL_REQUEST_TEMPLATE.md"
        "PULL_REQUEST_TEMPLATE.md"
    )
    for loc in "${locations[@]}"; do
        if [[ -f "${repo_root}/${loc}" ]]; then
            printf '%s\n' "${repo_root}/${loc}"
            return 0
        fi
    done
    return 1
}

# ---------------------------------------------------------------------------
# gather_diff_context
# ---------------------------------------------------------------------------
gather_diff_context() {
    echo "Gathering diff context..."

    DIFF_STAT=$(git diff --stat \
        "${MAIN_REMOTE}/${DEFAULT_BRANCH}...HEAD")
    FULL_DIFF=$(git diff \
        "${MAIN_REMOTE}/${DEFAULT_BRANCH}...HEAD")
    COMMIT_LOG=$(git log --oneline \
        "${MAIN_REMOTE}/${DEFAULT_BRANCH}..HEAD")

    local file_count
    file_count=$(echo "${DIFF_STAT}" | grep -c '|' || true)
    echo "  ✓ Diff stat: ${file_count} files changed"

    local commit_count
    commit_count=$(echo "${COMMIT_LOG}" | wc -l \
        | tr -d ' ')
    echo "  ✓ Commit log: ${commit_count} commits"

    PR_TEMPLATE=""
    TEMPLATE_PATH=""
    local tmpl_path
    if tmpl_path=$(find_pr_template); then
        TEMPLATE_PATH="${tmpl_path}"
        PR_TEMPLATE=$(cat "${tmpl_path}")
        echo "  ✓ PR template: found at ${TEMPLATE_PATH}"
    else
        echo "  ✓ PR template: not found"
    fi
}

# ---------------------------------------------------------------------------
# generate_pr_content
# ---------------------------------------------------------------------------
generate_pr_content() {
    echo "Generating PR title and description via Copilot CLI..."

    local prompt
    prompt="Generate a pull request title and description.

RULES FOR OUTPUT FORMAT:
- Line 1: The PR title (plain text only)
- Line 2: MUST be blank
- Lines 3+: The PR description in markdown

RULES FOR THE TITLE:
- Noun phrase (do NOT start with a verb)
- Maximum 72 characters
- First word capitalized
- No conventional commit prefixes (no fix:, feat:, chore:, etc.)

RULES FOR THE DESCRIPTION:"

    if [[ -n "${PR_TEMPLATE}" ]]; then
        prompt="${prompt}
- Follow the structure of the PR template below exactly
- Preserve all checkboxes as checkboxes (do NOT convert to bullets)
- Fill in sections based on the diff and commit context

PR TEMPLATE:
${PR_TEMPLATE}"
    else
        prompt="${prompt}
- Include a summary of the changes
- Include a list of modified files with brief descriptions
- Include relevant context from the commit messages"
    fi

    prompt="${prompt}

DIFF STAT:
${DIFF_STAT}

COMMIT LOG:
${COMMIT_LOG}

FULL DIFF:
${FULL_DIFF}"

    local copilot_output
    copilot_output=$(printf '%s\n' "${prompt}" \
        | copilot --silent --model "${COPILOT_MODEL}") || {
        echo "ERROR: Copilot CLI invocation failed." >&2
        exit 1
    }

    PR_TITLE=$(printf '%s\n' "${copilot_output}" | head -1)
    PR_DESCRIPTION=$(printf '%s\n' "${copilot_output}" | tail -n +3)

    if [[ -z "${PR_TITLE}" ]]; then
        echo "ERROR: Copilot CLI returned an empty title." >&2
        exit 1
    fi

    if [[ -z "${PR_DESCRIPTION}" ]]; then
        echo "ERROR: Copilot CLI returned an empty" \
            "description." >&2
        exit 1
    fi

    echo "  ✓ Content generated"
    echo "  Title: ${PR_TITLE}"
}

# ---------------------------------------------------------------------------
# create_pr
# ---------------------------------------------------------------------------
create_pr() {
    echo "Creating pull request..."

    local body_file
    body_file=$(mktemp)
    TEMP_FILES+=("${body_file}")
    printf '%s\n' "${PR_DESCRIPTION}" > "${body_file}"

    local main_url
    main_url=$(git remote get-url "${MAIN_REMOTE}")
    MAIN_REPO=$(printf '%s\n' "${main_url}" \
        | sed -E 's|.*[:/]([^/]+/[^/]+?)(.git)?$|\1|')

    local head_ref="${CURRENT_BRANCH}"
    if [[ "${BRANCH_REMOTE}" != "${MAIN_REMOTE}" ]]; then
        local branch_owner
        branch_owner=$(get_remote_owner "${BRANCH_REMOTE}")
        head_ref="${branch_owner}:${CURRENT_BRANCH}"
    fi

    PR_URL=$(gh pr create \
        --base "${DEFAULT_BRANCH}" \
        --head "${head_ref}" \
        --repo "${MAIN_REPO}" \
        --title "${PR_TITLE}" \
        --body-file "${body_file}") || {
        echo "ERROR: Failed to create PR." >&2
        exit 1
    }

    echo "  ✓ PR created"
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
    echo "${SEPARATOR}"
    echo "PR Creation Script"
    echo "${SEPARATOR}"

    validate_prerequisites
    detect_remote_config
    determine_default_branch
    validate_preconditions
    fetch_default_branch
    gather_diff_context
    generate_pr_content

    if [[ "${DRY_RUN}" == true ]]; then
        echo "${SEPARATOR}"
        echo "DRY RUN — PR was not created"
        echo "${SEPARATOR}"
        echo "Title: ${PR_TITLE}"
        echo ""
        echo "Description:"
        echo "${PR_DESCRIPTION}"
        echo "${SEPARATOR}"
    else
        create_pr

        echo "${SEPARATOR}"
        echo "PR created successfully!"
        echo "URL: ${PR_URL}"
        echo "${SEPARATOR}"
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

main
