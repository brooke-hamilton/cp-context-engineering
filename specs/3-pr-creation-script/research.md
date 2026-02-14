# Research: PR Creation Shell Script

<!-- markdownlint-disable MD024 -->

**Feature**: PR Creation Shell Script  
**Spec Directory**: `specs/3-pr-creation-script`  
**Date**: February 14, 2026

## Research Tasks

This document consolidates research findings for building a standalone shell script that creates GitHub pull requests with AI-generated titles and descriptions using the Copilot CLI.

---

## 1. GitHub CLI (`gh`) PR Creation with Forks

### Decision

Use `gh pr create` with explicit `--base`, `--head`, `--title`, and `--body` flags. For fork PRs, use the `owner:branch` syntax in `--head`.

### Key Flags

| Flag | Description |
|------|-------------|
| `-B`, `--base <branch>` | Target branch for the PR |
| `-H`, `--head <branch>` | Source branch (supports `owner:branch` for forks) |
| `-R`, `--repo <OWNER/REPO>` | Target repository |
| `-t`, `--title <string>` | PR title |
| `-b`, `--body <string>` | PR body text |
| `-F`, `--body-file <file>` | Read body from file (use for long descriptions) |

### Fork Head Syntax

```bash
# Non-fork: simple branch name
gh pr create --base main --head feature-branch --title "..." --body "..."

# Fork: owner:branch format
gh pr create --base main --head forkowner:feature-branch --repo mainowner/repo --title "..." --body "..."
```

### Rationale

- `--head owner:branch` is the documented approach for cross-repository PRs
- `--body-file` with a temp file is safer than `--body` for multi-line descriptions with special characters
- `gh pr create` returns the PR URL on stdout upon success

### Alternatives Considered

- **GitHub REST API via `curl`**: More complex, requires manual token management. Rejected in favor of `gh` which handles auth transparently.
- **GitHub MCP tools**: Not available in a standalone script context. MCP is for agent-based workflows.

### Sources

- GitHub CLI documentation: `gh pr create --help`
- GitHub CLI manual: PRs from forks use `owner:branch` head syntax

---

## 2. Default Branch Detection

### Decision

Use a two-step approach: try `git symbolic-ref` first (fast, no network), then fall back to `gh repo view` (authoritative, requires network).

### Implementation

```bash
# Step 1: Try local symbolic-ref (fast, offline)
default_branch=$(git symbolic-ref "refs/remotes/${main_remote}/HEAD" 2>/dev/null \
    | sed "s@^refs/remotes/${main_remote}/@@")

# Step 2: Fallback to gh repo view (network call)
if [[ -z "${default_branch}" ]]; then
    git remote set-head "${main_remote}" --auto
    default_branch=$(git symbolic-ref "refs/remotes/${main_remote}/HEAD" \
        | sed "s@^refs/remotes/${main_remote}/@@")
fi
```

### Rationale

- `git symbolic-ref` is instant and works offline when `refs/remotes/origin/HEAD` is set
- `git remote set-head --auto` fetches and sets HEAD from remote if missing
- `gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'` is an alternative but requires the `gh` CLI network call

### Alternatives Considered

- **`git remote show origin`**: Makes a network call and parses text output — fragile
- **`gh api`**: More complex than `gh repo view` for simple branch lookup
- **Hardcoding `main`**: Rejected because many repos still use `master` or custom default branches

---

## 3. Fork Detection Algorithm

### Decision

Auto-detect fork configuration using a two-strategy approach matching the spec requirements, with no command-line options required.

### Algorithm

```
Strategy 1: Check for `upstream` remote
  → If present: clone-from-fork (origin=fork, upstream=main repo)
  → MAIN_REMOTE=upstream, FORK_REMOTE=origin

Strategy 2: Check if branch exists on non-origin, non-upstream remote
  → If found: clone-from-main with fork remote
  → MAIN_REMOTE=origin, FORK_REMOTE=<detected remote>

Fallback: No fork detected
  → MAIN_REMOTE=origin, FORK_REMOTE="" (empty)
```

### Key Commands

```bash
# Check if upstream remote exists
git remote get-url upstream 2>/dev/null

# Check which remotes have the branch
git ls-remote --heads <remote> <branch>

# Extract owner from remote URL (HTTPS or SSH)
git remote get-url <remote> | sed -E 's|.*[:/]([^/]+)/[^/]+(.git)?$|\1|'
```

### Rationale

- Strategy 1 (upstream remote) covers the most common fork workflow
- Strategy 2 (branch on non-origin remote) covers the "clone-from-main, add fork" workflow
- Both strategies are deterministic from git remote state — no user input needed
- When the branch exists on multiple non-main remotes, use the first one found

### Alternatives Considered

- **`gh repo view --json isFork`**: Would require checking each remote's repo, adding API calls. Rejected for simplicity.
- **Command-line flag for fork mode**: Rejected per spec — auto-detection is mandatory.

---

## 4. Pre-condition Validation Commands

### Decision

Validate four ordered pre-conditions using standard git commands, stopping on first failure.

### Validation Checks

| Check | Command | Failure Condition |
|-------|---------|-------------------|
| 1. Not on default branch | `git rev-parse --abbrev-ref HEAD` | Current branch equals default branch |
| 2. No uncommitted changes | `git status --porcelain` | Non-empty output (unstaged or staged changes) |
| 3. Branch ahead of default | `git rev-list --count "${main_remote}/${default_branch}..HEAD"` | Count is 0 |
| 4. Branch pushed to remote | `git ls-remote --heads <remote> <branch>` | No output for any remote |

### Additional Check: Existing PR

```bash
existing_pr=$(gh pr list --head "${branch}" --json url --jq '.[0].url' 2>/dev/null)
if [[ -n "${existing_pr}" ]]; then
    echo "ERROR: PR already exists: ${existing_pr}" >&2
    exit 1
fi
```

### Rationale

- `git status --porcelain` captures both unstaged and staged-but-uncommitted changes in a parseable format
- `git rev-list --count` gives a numeric answer for "is the branch ahead"
- `git ls-remote --heads` checks the remote directly without needing a fetch
- `gh pr list --head` with `--json` gives machine-parseable output

---

## 5. Copilot CLI Invocation

### Decision

Invoke the standalone `copilot` binary on `$PATH` with a prompt that includes diff context, commit log, and optional PR template. The prompt instructs the CLI to return output in a parseable format (title on first line, description on remaining lines).

### Authentication Check

```bash
# Verify copilot CLI is installed
if ! command -v copilot &>/dev/null; then
    echo "ERROR: Copilot CLI not found. Install from https://github.com/github/copilot-cli" >&2
    exit 1
fi

# Verify authentication (exact command TBD — depends on copilot CLI version)
if ! copilot --version &>/dev/null; then
    echo "ERROR: Copilot CLI is not functional." >&2
    exit 1
fi
```

### Invocation Pattern

```bash
copilot_output=$(copilot -p "prompt text here" <<< "${context_input}")
```

The prompt instructs Copilot to return:

- Line 1: PR title (plain text, max 72 chars, noun phrase, no conventional commit prefix)
- Line 2: Empty separator line
- Lines 3+: PR description (markdown)

### Parsing Output

```bash
pr_title=$(echo "${copilot_output}" | head -1)
pr_description=$(echo "${copilot_output}" | tail -n +3)
```

### Rationale

- Single invocation for both title and description minimizes API calls and latency
- Line-based parsing is simple and robust for shell scripts
- The title formatting rules are enforced via the prompt, not post-processing
- Piping context via stdin allows large diffs without argument length limits

### Alternatives Considered

- **Two separate Copilot CLI calls** (one for title, one for description): More API overhead, rejected per spec
- **JSON output format**: More robust parsing but adds `jq` dependency for a simple two-field extraction
- **`gh copilot` (deprecated)**: Explicitly excluded per spec — the standalone `copilot` binary is required

### Open Assumptions

- The exact `copilot` CLI invocation syntax (flags for prompt input, stdin handling) may vary by version. The script should use the most standard invocation pattern available.
- Authentication verification may need adjustment depending on what commands the `copilot` CLI exposes for status checking.

---

## 6. PR Template Detection

### Decision

Search for PR templates in the standard GitHub locations, in order, and use the first one found.

### Search Order

1. `.github/PULL_REQUEST_TEMPLATE.md`
2. `.github/pull_request_template.md`
3. `docs/PULL_REQUEST_TEMPLATE.md`
4. `PULL_REQUEST_TEMPLATE.md`

### Implementation

```bash
find_pr_template() {
    local locations=(
        ".github/PULL_REQUEST_TEMPLATE.md"
        ".github/pull_request_template.md"
        "docs/PULL_REQUEST_TEMPLATE.md"
        "PULL_REQUEST_TEMPLATE.md"
    )
    for loc in "${locations[@]}"; do
        if [[ -f "${loc}" ]]; then
            echo "${loc}"
            return 0
        fi
    done
    return 1
}
```

### Rationale

- These are the standard locations documented by GitHub
- First-match wins, consistent with GitHub's own template resolution
- Case-sensitive check because filesystems may be case-sensitive

### Alternatives Considered

- **Recursive search for `*PULL_REQUEST_TEMPLATE*`**: Could find templates in unexpected locations. Rejected for predictability.
- **Multiple template support (template directories)**: Out of scope per spec.

---

## 7. `gh auth status` Validation

### Decision

Use `gh auth status` exit code to validate GitHub CLI authentication before any PR operations.

### Implementation

```bash
if ! gh auth status >/dev/null 2>&1; then
    echo "ERROR: Not authenticated to GitHub CLI. Run 'gh auth login'." >&2
    exit 1
fi
```

### Output Details

- **Exit 0**: Authenticated successfully
- **Exit 1**: Authentication issues (not logged in, token expired, etc.)
- Authenticated output includes account name, token type, and scopes
- Error output goes to stderr

### Rationale

- Exit code is sufficient for script validation — no need to parse output
- Redirecting output to `/dev/null` keeps script output clean (but only for the check itself, not for error display)
- This check should happen early, before any `gh` commands that require auth

---

## 8. Diff and Commit Log Gathering

### Decision

Gather both stat summary and full diff, plus commit log, between the current branch and the fetched default branch.

### Commands

```bash
# Fetch latest default branch first
git fetch "${main_remote}" "${default_branch}"

# Diff stat (summary of changed files)
diff_stat=$(git diff --stat "${main_remote}/${default_branch}...HEAD")

# Full diff
full_diff=$(git diff "${main_remote}/${default_branch}...HEAD")

# Commit log
commit_log=$(git log --oneline "${main_remote}/${default_branch}..HEAD")
```

### Three-dot vs Two-dot

- `git diff A...B` — changes on B since the common ancestor of A and B (what the PR would show)
- `git log A..B` — commits reachable from B but not A (commits in the PR)

### Rationale

- Three-dot diff (`...`) matches what GitHub shows in the PR diff view
- Two-dot log (`..`) gives the commits that will be in the PR
- Fetching the default branch first ensures comparison against current upstream state (FR-006a)
- Both stat and full diff are needed: stat for overview, full diff for detailed context

---

## 9. Shell Script Safety Patterns

### Decision

Follow the repository's shell scripting instructions (`cp.shell.instructions.md`) for all safety and style conventions.

### Key Patterns

| Pattern | Implementation |
|---------|---------------|
| Error handling | `set -euo pipefail` |
| Cleanup | `trap cleanup EXIT` with temp file removal |
| Variable quoting | `"${var}"` consistently |
| Temp files | `mktemp` with cleanup in trap |
| Conditionals | `[[ ]]` over `[ ]` |
| Functions | `lowercase_with_underscores()` |
| Constants | `readonly UPPER_CASE` |
| Indentation | 4 spaces |
| Line length | Max 80 characters |

### Body Text Handling

Use `--body-file` with a temp file instead of `--body` to safely handle multi-line descriptions with special characters:

```bash
body_file=$(mktemp)
echo "${pr_description}" > "${body_file}"
gh pr create --title "${pr_title}" --body-file "${body_file}" ...
```

### Rationale

- Temp file approach avoids shell quoting issues with markdown content
- `trap cleanup EXIT` ensures temp files are always cleaned up
- Consistent with existing script patterns in `.specify/scripts/bash/`

---

## 10. Extracting Remote Owner for Fork PRs

### Decision

Parse the remote URL to extract the GitHub owner/org name, needed for the `--head owner:branch` syntax in fork PRs.

### Implementation

```bash
get_remote_owner() {
    local remote_url
    remote_url=$(git remote get-url "$1")
    # Handle both HTTPS and SSH URLs
    echo "${remote_url}" | sed -E 's|.*[:/]([^/]+)/[^/]+(.git)?$|\1|'
}
```

### URL Patterns Handled

| Format | Example | Extracted Owner |
|--------|---------|----------------|
| HTTPS | `https://github.com/owner/repo.git` | `owner` |
| HTTPS (no .git) | `https://github.com/owner/repo` | `owner` |
| SSH | `git@github.com:owner/repo.git` | `owner` |

### Rationale

- Single regex handles both HTTPS and SSH URL formats
- Owner extraction is needed to construct `--head owner:branch` for `gh pr create`
- Also used to construct `--repo owner/repo` for the target repository

---

## Summary of Key Decisions

| Area | Decision | Confidence |
|------|----------|------------|
| PR creation tool | `gh pr create` with explicit flags | High |
| Default branch detection | `git symbolic-ref` with `gh` fallback | High |
| Fork detection | Two-strategy auto-detection (upstream remote, non-origin branch) | High |
| Pre-condition validation | Four ordered git checks | High |
| AI content generation | Standalone `copilot` CLI, single invocation | Medium |
| Output parsing | Line-based (title = line 1, description = line 3+) | Medium |
| PR template search | Four standard locations, first-match wins | High |
| Auth validation | `gh auth status` exit code + `copilot` availability check | High |
| Body text handling | Temp file via `--body-file` | High |
| Shell safety | `set -euo pipefail` + `trap` cleanup | High |

---

## References

- GitHub CLI documentation: PR creation, authentication, repository queries
- Git documentation: `rev-parse`, `symbolic-ref`, `ls-remote`, `diff`, `log`, `status`
- Repository shell instructions: `.github/instructions/cp.shell.instructions.md`
- Existing prompt: `.github/prompts/cp.create-pr.prompt.md` (source of truth for workflow)
