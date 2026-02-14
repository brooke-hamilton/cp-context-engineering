# Feature Specification: PR Creation Shell Script

**Spec Directory**: `specs/3-pr-creation-script`  
**Created**: 2026-02-14  
**Status**: Draft  
**Input**: User description: "Convert the cp.create-pr prompt into a shell script that uses the GitHub Copilot CLI (`copilot`) for model-generated content (PR title, description) while performing all git and GitHub CLI operations directly."

## Clarifications

### Session 2026-02-14

- Q: What is the specific invocation mechanism for AI-generated content (PR title, description)? → A: The GitHub Copilot CLI (`copilot`), which accepts prompts and returns generated text. The script pipes context (diffs, commit logs) to the Copilot CLI for title and description generation.
- Q: How does the script authenticate? → A: The script validates that the user is authenticated to both the `gh` CLI (via `gh auth status`) and the Copilot CLI before proceeding. If either authentication check fails, the script exits with a clear error message.
- Q: Where does the script file live and how is it invoked? → A: Standalone script at the repo root as `create-pr.sh`, invoked with `./create-pr.sh`.
- Q: Should the PR be created as a draft or ready for review? → A: Always ready for review (no `--draft` flag).
- Q: What is explicitly out of scope? → A: Labels, reviewer assignment, interactive title/description editing before creation, and multi-PR batch operations are all out of scope.
- Q: What output does the script produce during normal execution? → A: Verbose — show all git commands, CLI interactions, and intermediate results, plus the final PR URL.
- Q: Should the title and description be generated in one or two Copilot CLI calls? → A: Single call generating both. The output must use a parseable format so the script can extract the title and description separately for `gh pr create`.
- Q: How is the Copilot CLI invoked? → A: As a standalone binary `copilot` on `$PATH`, not via `gh copilot` (which is deprecated). It is a separate CLI from `gh`.

## User Scenarios & Testing *(mandatory)*

### Out of Scope

- Assigning labels to the PR
- Assigning reviewers to the PR
- Interactive editing of the generated title or description before PR creation
- Batch creation of multiple PRs in a single invocation

### User Story 1 - Create a PR from a non-fork branch (Priority: P1)

A developer is working on a feature branch in a repository they own (no fork). They have committed and pushed all changes. They run the script, which validates the branch state, gathers commit messages and diffs, uses the Copilot CLI (`copilot`) to generate a PR title and description, creates the PR via the GitHub CLI (`gh`), and displays the PR URL.

**Why this priority**: This is the most common PR creation workflow and the core value of the script.

**Independent Test**: Can be tested by running the script from any pushed feature branch in a non-forked repository and verifying a PR is created with an AI-generated title and description.

**Acceptance Scenarios**:

1. **Given** the user is on a feature branch with all changes committed and pushed to `origin`, and the repository has no `upstream` remote and no other fork remotes, **When** the user runs the script, **Then** the script determines the default branch from `origin`, fetches the latest default branch from `origin`, gathers the diff and commit log between the current branch and the fetched default branch, passes them to the Copilot CLI (`copilot`) for title/description generation, creates the PR via `gh pr create`, and displays the PR URL.
2. **Given** the user is on a feature branch with all changes committed and pushed, and no PR template exists in the repository, **When** the user runs the script, **Then** the Copilot CLI generates a description using a standard format that includes a summary of changes, a list of modified files with brief descriptions, and relevant context from commit messages.

---

### User Story 2 - Create a PR from a forked repository (Priority: P1)

A developer is contributing to an open-source project via a fork. There are two supported fork configurations, both fully auto-detected by the script:

- **Clone-from-fork**: The developer cloned their fork. `origin` points to the fork, and `upstream` points to the main repository. The script detects this by the presence of an `upstream` remote.
- **Clone-from-main with fork remote**: The developer cloned the main repository (`origin` = main repo) and added their fork as a separate remote. They pushed their branch to the fork remote. The script detects this by discovering that the branch exists on a non-`origin`, non-`upstream` remote.

In both cases, the script determines the correct default branch, creates the PR from the fork's branch to the main repository's default branch, and never pushes the branch to the main repository. No command-line options are required — the script infers the fork configuration entirely from the remote setup and which remote(s) the branch has been pushed to.

**Why this priority**: Fork-based contributions are a critical workflow and require distinct branching logic that must work correctly. Both remote configurations are common in practice.

**Independent Test**: Can be tested by running the script from a branch in a forked repository using either remote configuration.

**Acceptance Scenarios**:

1. **Given** the user is on a branch in a clone-from-fork repository with an `upstream` remote configured and the branch pushed to `origin` (the fork), **When** the user runs the script, **Then** the script detects the fork configuration, determines the default branch from `upstream` (not `origin`), fetches the latest default branch from `upstream`, and creates the PR targeting the upstream repository's default branch from the fork's branch.
2. **Given** the user cloned the main repository and added their fork as a remote named `myfork`, and pushed their branch to `myfork`, **When** the user runs the script, **Then** the script discovers the branch exists on `myfork` (not `origin`), determines the default branch from `origin` (the main repo), fetches the latest default branch from `origin`, and creates the PR from the fork's branch to the main repository's default branch.
3. **Given** the user is on a branch in a forked repository (either configuration), **When** the PR is created, **Then** the branch is NOT pushed to the main repository; the PR is created from the fork's branch.
4. **Given** the branch has been pushed to multiple non-main remotes, **When** the user runs the script, **Then** the script uses the remote where the branch was most recently pushed (or the first one found) and proceeds with PR creation.

---

### User Story 3 - Use a PR template when one exists (Priority: P2)

A developer runs the script in a repository that has a PR template file. The script detects the template, reads its contents, and passes it to the Copilot CLI so the generated PR description follows the template's structure, including properly marked checkboxes.

**Why this priority**: Many teams use PR templates for consistency, and the script should respect them when present.

**Independent Test**: Can be tested by adding a PR template to a repository and running the script, then verifying the generated description follows the template structure.

**Acceptance Scenarios**:

1. **Given** a repository has a PR template at `.github/PULL_REQUEST_TEMPLATE.md`, **When** the user runs the script, **Then** the script reads the template and includes it in the context passed to the Copilot CLI for description generation.
2. **Given** a repository has a PR template at any of the standard locations (`.github/PULL_REQUEST_TEMPLATE.md`, `.github/pull_request_template.md`, `docs/PULL_REQUEST_TEMPLATE.md`, `PULL_REQUEST_TEMPLATE.md`), **When** the user runs the script, **Then** the script finds and uses the first available template.
3. **Given** the PR template contains checkboxes, **When** the Copilot CLI generates the description, **Then** the checkboxes are preserved as checkboxes (not converted to bullet lists) and marked appropriately based on the changes.

---

### User Story 4 - Script stops on pre-condition failures (Priority: P2)

Before taking any other action, the script validates four ordered pre-conditions. If any fail, it stops immediately with a clear error message and instructions on what to do. The validations are:

1. The user is on a non-default branch (not `main`, `master`, etc.).
2. There are no uncommitted changes in the working directory (no unstaged modifications and no staged-but-uncommitted files).
3. The branch is ahead of the default branch (has commits to submit).
4. The branch has been pushed to at least one remote (either the main repo or a fork remote).

**Why this priority**: Clear failure messaging prevents confusion and wasted time. Validating early avoids wasted work.

**Independent Test**: Can be tested by running the script with uncommitted changes, unpushed commits, or a local-only branch, and verifying the script exits with the correct error message.

**Acceptance Scenarios**:

1. **Given** the user is on the default branch (e.g., `main`), **When** the user runs the script, **Then** the script exits with a message telling the user they must be on a feature branch, not the default branch.
2. **Given** the user is on a feature branch that has no commits ahead of the default branch, **When** the user runs the script, **Then** the script exits with a message indicating there are no changes to create a PR for.
3. **Given** the user has uncommitted changes in the working directory (either unstaged modifications or staged-but-uncommitted files), **When** the user runs the script, **Then** the script exits with a message telling the user to commit their changes.
4. **Given** the user has commits that have not been pushed to any remote, **When** the user runs the script, **Then** the script exits with a message telling the user to push their commits.
5. **Given** the current branch does not exist on any remote, **When** the user runs the script, **Then** the script exits with a message telling the user the branch must be pushed to a remote first.
6. **Given** a PR already exists for the current branch, **When** the user runs the script, **Then** the script exits with a message indicating a PR already exists and provides the existing PR URL.

---

### Edge Cases

- What happens when the user is on the default branch (e.g., `main`)? The script should exit with an error indicating that PRs cannot be created from the default branch.
- What happens when `gh` CLI is not installed or not authenticated? The script should detect this early (via `gh auth status`) and exit with a clear message.
- What happens when the user is not authenticated to the Copilot CLI? The script should detect this early and exit with a clear message.
- What happens when the Copilot CLI (`copilot`) is not installed or not functional? The script should detect this early and exit with a clear message.
- What happens when there are no commits between the current branch and the default branch? The script should exit with a message indicating there are no changes to create a PR for.
- What happens when the git remote `origin` is not configured? The script should exit with an error.
- What happens when the branch has been pushed to multiple non-main remotes? The script should select one (first found or most recently pushed) and proceed.
- What happens when the branch exists on both `origin` (the main repo) and a fork remote? The script should prefer the fork remote for PR creation, since PRs from forks are the expected workflow when fork remotes exist.
- What happens when the fetch of the default branch fails (e.g., network error, permission denied)? The script should exit with a clear error indicating the fetch failed and suggesting the user check their network connection and remote permissions.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Script MUST validate four ordered pre-conditions before proceeding: (1) the current branch is not the default branch, (2) there are no uncommitted changes (no unstaged modifications and no staged-but-uncommitted files), (3) the branch is ahead of the default branch, (4) the branch has been pushed to at least one remote. If any fail, the script MUST exit with a clear error message and instructions.
- **FR-002**: Script MUST check for uncommitted changes — both unstaged modifications and staged-but-uncommitted files — and exit with an error if any exist.
- **FR-003**: Script MUST check for unpushed commits and exit with an error if any exist.
- **FR-004**: Script MUST determine which remote(s) the current branch has been pushed to by checking all configured remotes.
- **FR-005**: Script MUST detect fork configuration automatically, without requiring any command-line options, using two methods: (a) if an `upstream` remote exists, the clone is from a fork (`origin` = fork, `upstream` = main repo), or (b) if no `upstream` exists but the branch has been pushed to a remote other than `origin`, that remote is the fork and `origin` is the main repo.
- **FR-006**: Script MUST determine the default branch from `upstream` when auto-detected as a clone-from-fork, or from `origin` in all other cases (clone-from-main with fork remote, or no fork).
- **FR-006a**: Script MUST fetch the latest default branch from the appropriate remote (`upstream` or `origin`) before comparing the current branch to the default branch for diffs and commit logs. This ensures the diff reflects the current state of the target branch, not a stale local copy.
- **FR-007**: Script MUST search for a PR template at these locations in order: `.github/PULL_REQUEST_TEMPLATE.md`, `.github/pull_request_template.md`, `docs/PULL_REQUEST_TEMPLATE.md`, `PULL_REQUEST_TEMPLATE.md`.
- **FR-008**: Script MUST gather the commit log between the current branch and the default branch.
- **FR-009**: Script MUST gather the diff (both `--stat` summary and full diff) between the current branch and the default branch.
- **FR-010**: Script MUST use a single Copilot CLI (`copilot`) invocation to generate both the PR title and description, providing the diff, commit log, and PR template (if found) as context. The prompt MUST instruct the Copilot CLI to return the output in a parseable format (e.g., first line is the title, remaining lines are the description) so the script can extract each field separately.
- **FR-011**: The generated PR title MUST follow these formatting rules: noun phrase (not starting with a verb), max 72 characters, first word capitalized, no conventional commit prefixes.
- **FR-012**: The script MUST parse the Copilot CLI output to extract the title and description as separate values for passing to `gh pr create`.
- **FR-013**: When a PR template is provided as context, the generated description MUST follow the template's structure and preserve checkboxes as checkboxes.
- **FR-014**: When no PR template exists, the generated description MUST include a summary of changes, a list of modified files with brief descriptions, and relevant context from commit messages.
- **FR-015**: Script MUST verify `gh` CLI is installed and authenticated (via `gh auth status`) before attempting PR creation. Script MUST also verify that the Copilot CLI (`copilot`) is installed and that the user is authenticated to it before attempting content generation.
- **FR-016**: Script MUST create the PR using `gh pr create` with the correct base and head branches. The PR MUST be created as ready for review (not as a draft).
- **FR-017**: When a fork configuration is detected (either via `upstream` remote or by discovering the branch on a non-`origin` remote), the PR MUST be created from the fork's branch to the main repository's default branch, without pushing the branch to the main repository.
- **FR-018**: Script MUST check if a PR already exists for the current branch and exit with the existing PR URL if so.
- **FR-019**: Script MUST display verbose output during execution, including git commands being run, CLI interactions, and intermediate results, followed by a success message with the PR URL upon completion.
- **FR-020**: Script MUST exit immediately with a clear, descriptive error message when any step fails.
- **FR-021**: Script MUST verify the Copilot CLI (`copilot`) is installed and the user is authenticated to it. If the Copilot CLI is not installed or the user is not authenticated, the script MUST exit with a clear error message indicating how to install and authenticate.

### Key Entities

- **Current Branch**: The git branch the user is working on, from which the PR will be created.
- **Default Branch**: The target branch for the PR (e.g., `main` or `master`), determined from `upstream` (fork) or `origin` (non-fork).
- **Remote Configuration**: The set of git remotes (`origin`, `upstream`, and any additional remotes) that determine fork status and target repository. Three configurations are auto-detected: (1) non-fork (`origin` only, branch pushed to `origin`), (2) clone-from-fork (`origin` = fork, `upstream` = main repo, detected by presence of `upstream`), (3) clone-from-main with fork (`origin` = main repo, branch pushed to a different remote, detected by discovering the branch on a non-`origin` remote).
- **PR Template**: An optional markdown file in the repository that defines the structure for PR descriptions.
- **Diff Context**: The combination of `git diff` output and `git log` output between the current branch and the default branch, used as input for the Copilot CLI to generate PR content.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can create a complete PR (with AI-generated title and description) by running a single command, without any interactive prompts during normal operation.
- **SC-002**: The script correctly auto-detects all three remote configurations (non-fork, clone-from-fork, clone-from-main with fork remote) and targets the appropriate default branch in 100% of cases.
- **SC-003**: All pre-condition failures (uncommitted changes, unpushed commits, branch not on remote, existing PR) are caught before any PR creation is attempted.
- **SC-004**: When a PR template exists, the generated description follows the template structure and preserves checkbox formatting.
- **SC-005**: The script completes the full PR creation workflow (validation through PR creation) without requiring manual intervention.

## Assumptions

- The script is a standalone bash file located at `create-pr.sh` in the repository root, invoked with `./create-pr.sh`. No installation step or `$PATH` modification is required.

- The GitHub Copilot CLI (`copilot`) is a standalone binary on the user's `$PATH`, separate from the `gh` CLI (the deprecated `gh copilot` extension is not used). The user is authenticated to it. The script validates authentication for both the `gh` CLI (via `gh auth status`) and the Copilot CLI before proceeding. The script passes context (diffs, commit logs, prompts) to the Copilot CLI and receives generated text output.
- The `gh` CLI is the primary mechanism for creating PRs, and the Copilot CLI (`copilot`) is the mechanism for AI-generated content (no MCP tool dependency or direct REST API calls since this is a standalone script).
- The script runs in a bash-compatible shell environment.
- The user has appropriate GitHub permissions to create PRs in the target repository.
- The PR title formatting rules (noun phrase, no verb prefix, no conventional commits) are enforced via the prompt sent to the Copilot CLI, not by the script parsing the output.
