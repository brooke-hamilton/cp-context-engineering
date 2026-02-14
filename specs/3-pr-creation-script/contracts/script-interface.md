# Contracts: PR Creation Shell Script

**Feature**: PR Creation Shell Script  
**Spec Directory**: `specs/3-pr-creation-script`  
**Date**: February 14, 2026

## Script Interface

### Invocation

```bash
./create-pr.sh
```

No arguments. No flags. All behavior is auto-detected from git state.

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | PR created successfully |
| 1 | Pre-condition failure or runtime error |

### Environment Requirements

| Requirement | Validation |
|-------------|------------|
| `gh` CLI installed | `command -v gh` |
| `gh` CLI authenticated | `gh auth status` exit code 0 |
| `copilot` CLI installed | `command -v copilot` |
| `copilot` CLI authenticated | `copilot` accessibility check |
| Git repository | `git rev-parse --git-dir` |
| At least one remote | `git remote` non-empty |

---

## Function Contracts

### `validate_prerequisites`

Checks that required CLI tools are installed and authenticated.

**Inputs**: None (reads environment)  
**Outputs**: None (exits on failure)  
**Side effects**: Exits with code 1 and error message if any tool is missing or not authenticated

**Error Messages**:

- `ERROR: git is not installed.`
- `ERROR: GitHub CLI (gh) is not installed. Install from https://cli.github.com`
- `ERROR: Not authenticated to GitHub CLI. Run 'gh auth login'.`
- `ERROR: Copilot CLI (copilot) is not found on PATH. See installation docs.`
- `ERROR: Copilot CLI is not functional. Check authentication.`

---

### `detect_remote_config`

Determines fork configuration from git remotes.

**Inputs**: None (reads git remote state)  
**Outputs**: Sets global variables:

- `MAIN_REMOTE` — remote name for the main repo
- `FORK_REMOTE` — remote name for the fork (empty string if no fork)
- `IS_FORK` — `true` or `false`
- `FORK_OWNER` — GitHub owner of the fork remote

**Algorithm**:

1. If `upstream` remote exists → `MAIN_REMOTE=upstream`, `FORK_REMOTE=origin`
2. Else if branch exists on a non-`origin` remote → `MAIN_REMOTE=origin`, `FORK_REMOTE=<detected>`
3. Else → `MAIN_REMOTE=origin`, `FORK_REMOTE=""`

---

### `determine_default_branch`

Finds the default branch name from the main remote.

**Inputs**: `MAIN_REMOTE` (global variable)  
**Outputs**: Sets `DEFAULT_BRANCH` global variable  
**Side effects**: May run `git remote set-head` if symbolic-ref lookup fails. Exits with error if default branch cannot be determined.

---

### `validate_preconditions`

Validates four ordered pre-conditions plus existing PR check.

**Inputs**: `CURRENT_BRANCH`, `DEFAULT_BRANCH`, `MAIN_REMOTE` (global variables)  
**Outputs**: None (exits on failure)  
**Validation order**:

1. Current branch is not the default branch
2. Working directory is clean (no unstaged or staged changes)
3. Current branch has commits ahead of default branch
4. Branch has been pushed to at least one remote
5. No PR already exists for this branch

**Error Messages**:

- `ERROR: Cannot create PR from the default branch '${DEFAULT_BRANCH}'. Switch to a feature branch.`
- `ERROR: Uncommitted changes detected. Commit or stash your changes before creating a PR.`
- `ERROR: No commits ahead of '${DEFAULT_BRANCH}'. Nothing to create a PR for.`
- `ERROR: Branch '${CURRENT_BRANCH}' has not been pushed to any remote. Run 'git push' first.`
- `ERROR: A PR already exists for branch '${CURRENT_BRANCH}': ${existing_url}`

---

### `fetch_default_branch`

Fetches the latest state of the default branch from the appropriate remote.

**Inputs**: `MAIN_REMOTE`, `DEFAULT_BRANCH` (global variables)  
**Outputs**: None (updates git refs)  
**Side effects**: Runs `git fetch`. Exits with error if fetch fails.

---

### `gather_diff_context`

Collects diff stat, full diff, commit log, and PR template.

**Inputs**: `MAIN_REMOTE`, `DEFAULT_BRANCH` (global variables)  
**Outputs**: Sets global variables:

- `DIFF_STAT` — stat summary
- `FULL_DIFF` — full diff output
- `COMMIT_LOG` — one-line commit log
- `PR_TEMPLATE` — template file contents (empty if none found)
- `TEMPLATE_PATH` — path to template (empty if none found)

---

### `find_pr_template`

Searches for PR template in standard locations.

**Inputs**: None (reads filesystem)  
**Outputs**: Prints template path to stdout, returns 0 if found, 1 if not found

**Search Order**:

1. `.github/PULL_REQUEST_TEMPLATE.md`
2. `.github/pull_request_template.md`
3. `docs/PULL_REQUEST_TEMPLATE.md`
4. `PULL_REQUEST_TEMPLATE.md`

---

### `generate_pr_content`

Invokes the Copilot CLI to generate PR title and description.

**Inputs**: `DIFF_STAT`, `FULL_DIFF`, `COMMIT_LOG`, `PR_TEMPLATE` (global variables)  
**Outputs**: Sets global variables:

- `PR_TITLE` — extracted title (line 1 of output)
- `PR_DESCRIPTION` — extracted description (line 3+ of output)

**Copilot CLI Prompt Contract**:

The prompt sent to the Copilot CLI must instruct it to:

1. Generate a PR title on the first line
2. Leave the second line blank
3. Generate the PR description starting on the third line
4. Follow title formatting rules: noun phrase, max 72 chars, first word capitalized, no conventional commit prefixes, no verb prefix
5. If a PR template is provided, follow its structure and preserve checkboxes
6. If no template, include: summary, modified files list, and commit context

---

### `create_pr`

Creates the PR using `gh pr create`.

**Inputs**: `PR_TITLE`, `PR_DESCRIPTION`, `DEFAULT_BRANCH`, `CURRENT_BRANCH`, `MAIN_REMOTE`, `FORK_REMOTE`, `FORK_OWNER`, `IS_FORK` (global variables)  
**Outputs**: Sets `PR_URL` global variable  
**Side effects**: Creates a PR on GitHub. Exits with error if creation fails.

**`gh pr create` invocation**:

For non-fork:

```bash
gh pr create \
    --base "${DEFAULT_BRANCH}" \
    --head "${CURRENT_BRANCH}" \
    --title "${PR_TITLE}" \
    --body-file "${body_temp_file}"
```

For fork:

```bash
gh pr create \
    --base "${DEFAULT_BRANCH}" \
    --head "${FORK_OWNER}:${CURRENT_BRANCH}" \
    --repo "${MAIN_REPO}" \
    --title "${PR_TITLE}" \
    --body-file "${body_temp_file}"
```

---

## Verbose Output Contract

The script outputs progress to stdout during execution. Format:

```shell
============================================================================
PR Creation Script
============================================================================
Checking prerequisites...
  ✓ git is available
  ✓ GitHub CLI (gh) is authenticated
  ✓ Copilot CLI (copilot) is available
Detecting remote configuration...
  Remote setup: <non-fork|clone-from-fork|clone-from-main-with-fork>
  Main remote: <remote_name>
  Fork remote: <remote_name or "none">
Determining default branch...
  Default branch: <branch_name>
Validating pre-conditions...
  ✓ On feature branch '<branch>'
  ✓ Working directory is clean
  ✓ <N> commit(s) ahead of '<default_branch>'
  ✓ Branch pushed to '<remote>'
  ✓ No existing PR for this branch
Fetching latest '<default_branch>' from '<remote>'...
  ✓ Fetch complete
Gathering diff context...
  ✓ Diff stat: <N> files changed
  ✓ Commit log: <N> commits
  ✓ PR template: <found at path|not found>
Generating PR title and description via Copilot CLI...
  ✓ Content generated
  Title: <generated title>
Creating pull request...
  ✓ PR created
============================================================================
PR created successfully!
URL: <pr_url>
============================================================================
```

Errors go to stderr with `ERROR:` prefix.
