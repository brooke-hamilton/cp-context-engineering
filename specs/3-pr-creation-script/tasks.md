# Tasks: PR Creation Shell Script

**Input**: Design documents from `/specs/3-pr-creation-script/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/script-interface.md

**Tests**: Not requested. No test tasks are included.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story. All tasks modify a single file (`create-pr.sh`) at the repository root.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (independent functions, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- All file paths reference `create-pr.sh` at the repository root

## Phase 1: Setup

**Purpose**: Create the script file with safety settings, cleanup trap, and structural skeleton

- [ ] T001 Create `create-pr.sh` with shebang, `set -euo pipefail`, header comment, global variable declarations, `cleanup` function with `trap cleanup EXIT` for temp file removal, and empty `main` function stub. Make the file executable. Follow the script template from `.github/instructions/cp.shell.instructions.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared utility functions required by ALL user stories. These functions handle tool validation, remote detection, and default branch resolution.

**CRITICAL**: No user story work can begin until this phase is complete.

- [ ] T002 Implement `validate_prerequisites` function in `create-pr.sh` that checks `git` is available (`command -v git`), `gh` CLI is installed (`command -v gh`) and authenticated (`gh auth status`), and `copilot` CLI is installed (`command -v copilot`) and functional. Exit with specific error messages from contracts/script-interface.md on any failure
- [ ] T003 [P] Implement `get_remote_owner` helper function in `create-pr.sh` that extracts the GitHub owner from a remote URL, handling both HTTPS (`https://github.com/owner/repo.git`) and SSH (`git@github.com:owner/repo.git`) formats using the sed pattern from research.md section 10
- [ ] T004 Implement `detect_remote_config` function in `create-pr.sh` that sets `MAIN_REMOTE`, `FORK_REMOTE`, `IS_FORK`, and `FORK_OWNER` global variables using the two-strategy algorithm: (1) if `upstream` remote exists, set `MAIN_REMOTE=upstream` and `FORK_REMOTE=origin`, (2) else if branch exists on a non-`origin` non-`upstream` remote via `git ls-remote --heads`, set `MAIN_REMOTE=origin` and `FORK_REMOTE=<detected>`, (3) else set `MAIN_REMOTE=origin` and `FORK_REMOTE=""`. Use `get_remote_owner` to populate `FORK_OWNER`
- [ ] T005 Implement `determine_default_branch` function in `create-pr.sh` that sets the `DEFAULT_BRANCH` global variable by first trying `git symbolic-ref refs/remotes/${MAIN_REMOTE}/HEAD`, falling back to `git remote set-head ${MAIN_REMOTE} --auto` then retrying. Exit with error if default branch cannot be determined

**Checkpoint**: Foundation ready — user story implementation can begin

---

## Phase 3: User Story 1 - Create a PR From a Non-Fork Branch (Priority: P1) MVP

**Goal**: A developer on a feature branch with pushed commits runs `./create-pr.sh` and gets a PR created with an AI-generated title and description, with no interactive prompts.

**Independent Test**: Run the script from a pushed feature branch in a non-forked repository. Verify a PR is created with a generated title and description, and the PR URL is displayed.

### Implementation for User Story 1

- [ ] T006 [US1] Implement `validate_preconditions` function in `create-pr.sh` with four ordered checks: (1) current branch is not `DEFAULT_BRANCH` via `git rev-parse --abbrev-ref HEAD`, (2) working directory is clean via `git status --porcelain`, (3) branch has commits ahead via `git rev-list --count`, (4) branch is pushed to at least one remote via `git ls-remote --heads`. Exit on first failure with error messages from contracts/script-interface.md
- [ ] T007 [P] [US1] Implement `fetch_default_branch` function in `create-pr.sh` that runs `git fetch ${MAIN_REMOTE} ${DEFAULT_BRANCH}` and exits with a clear error if the fetch fails
- [ ] T008 [US1] Implement `gather_diff_context` function in `create-pr.sh` that sets `DIFF_STAT` via `git diff --stat ${MAIN_REMOTE}/${DEFAULT_BRANCH}...HEAD`, `FULL_DIFF` via `git diff ${MAIN_REMOTE}/${DEFAULT_BRANCH}...HEAD`, and `COMMIT_LOG` via `git log --oneline ${MAIN_REMOTE}/${DEFAULT_BRANCH}..HEAD`. Initialize `PR_TEMPLATE` and `TEMPLATE_PATH` as empty strings
- [ ] T009 [US1] Implement `generate_pr_content` function in `create-pr.sh` that constructs a prompt instructing the Copilot CLI to return a PR title on line 1 (noun phrase, max 72 chars, capitalized, no conventional commit prefix), blank line 2, and markdown description on lines 3+. Pipe diff stat, full diff, commit log, and PR template (if any) as context. Parse output to set `PR_TITLE` (line 1) and `PR_DESCRIPTION` (line 3+). Exit with error if either is empty
- [ ] T010 [US1] Implement `create_pr` function in `create-pr.sh` for the non-fork path: write `PR_DESCRIPTION` to a temp file via `mktemp`, run `gh pr create --base ${DEFAULT_BRANCH} --head ${CURRENT_BRANCH} --title "${PR_TITLE}" --body-file "${body_file}"`, capture the PR URL, and exit with error if creation fails
- [ ] T011 [US1] Wire up the `main` function in `create-pr.sh` to call all functions in order: `validate_prerequisites`, `detect_remote_config`, `determine_default_branch`, `validate_preconditions`, `fetch_default_branch`, `gather_diff_context`, `generate_pr_content`, `create_pr`. Add verbose output matching the output contract from contracts/script-interface.md (section separators, checkmarks for each step, final PR URL display)

**Checkpoint**: Non-fork PR creation is fully functional. Script can be used for the most common workflow.

---

## Phase 4: User Story 2 - Create a PR From a Forked Repository (Priority: P1)

**Goal**: A developer contributing via a fork (either clone-from-fork or clone-from-main-with-fork-remote) runs the script and gets a PR created from the fork's branch to the main repository's default branch, with fork configuration auto-detected.

**Independent Test**: Run the script from a branch in a forked repository using either remote configuration. Verify the PR targets the main repository's default branch from the fork's branch.

### Implementation for User Story 2

- [ ] T012 [US2] Extend `create_pr` function in `create-pr.sh` to handle fork PRs: when `IS_FORK` is `true`, construct `MAIN_REPO` as `owner/repo` from `MAIN_REMOTE` URL, run `gh pr create --base ${DEFAULT_BRANCH} --head ${FORK_OWNER}:${CURRENT_BRANCH} --repo ${MAIN_REPO} --title "${PR_TITLE}" --body-file "${body_file}"`. Ensure the branch is never pushed to the main repository
- [ ] T013 [US2] Update verbose output in `main` function in `create-pr.sh` to display fork detection details: remote setup type (non-fork, clone-from-fork, clone-from-main-with-fork), main remote name, fork remote name or "none", and fork owner

**Checkpoint**: Both fork and non-fork PR workflows are functional. All P1 user stories are complete.

---

## Phase 5: User Story 3 - Use a PR Template When One Exists (Priority: P2)

**Goal**: When a repository has a PR template, the script detects it and passes it to the Copilot CLI so the generated description follows the template's structure, including preserved checkboxes.

**Independent Test**: Add a PR template to a repository, run the script, and verify the generated description follows the template structure with checkboxes preserved.

### Implementation for User Story 3

- [ ] T014 [P] [US3] Implement `find_pr_template` function in `create-pr.sh` that searches four standard locations in order (`.github/PULL_REQUEST_TEMPLATE.md`, `.github/pull_request_template.md`, `docs/PULL_REQUEST_TEMPLATE.md`, `PULL_REQUEST_TEMPLATE.md`), prints the path to stdout and returns 0 if found, returns 1 if not found
- [ ] T015 [US3] Update `gather_diff_context` function in `create-pr.sh` to call `find_pr_template`, and if a template is found, read its contents into `PR_TEMPLATE` and set `TEMPLATE_PATH` to the discovered path
- [ ] T016 [US3] Update the Copilot CLI prompt in `generate_pr_content` in `create-pr.sh` to include the PR template contents when `PR_TEMPLATE` is non-empty, instructing the Copilot CLI to follow the template structure and preserve checkboxes as checkboxes (not converting them to bullet lists)

**Checkpoint**: PR template detection and integration is functional. Generated descriptions follow template structure.

---

## Phase 6: User Story 4 - Script Stops on Pre-Condition Failures (Priority: P2)

**Goal**: Before taking any action, the script validates pre-conditions in order and stops with clear error messages and remediation instructions on the first failure.

**Independent Test**: Run the script with uncommitted changes, unpushed commits, on the default branch, or with an existing PR, and verify the script exits with the correct error message and remediation instruction.

### Implementation for User Story 4

- [ ] T017 [US4] Add existing PR detection to `validate_preconditions` in `create-pr.sh`: after the four ordered checks, query `gh pr list --head ${CURRENT_BRANCH} --json url --jq '.[0].url'` and if a PR exists, exit with `ERROR: A PR already exists for branch '${CURRENT_BRANCH}': ${existing_url}`
- [ ] T018 [US4] Review and refine all error messages in `validate_preconditions` in `create-pr.sh` to match the exact messages from contracts/script-interface.md, ensuring each includes actionable remediation instructions (e.g., "Switch to a feature branch", "Commit or stash your changes", "Run 'git push' first")

**Checkpoint**: All pre-condition failures produce clear, actionable error messages. All P2 user stories are complete.

---

## Phase 7: Polish and Cross-Cutting Concerns

**Purpose**: Final validation, linting, and documentation

- [ ] T019 [P] Verify `create-pr.sh` passes `shellcheck` static analysis with no errors or warnings
- [ ] T020 [P] Verify `create-pr.sh` follows all formatting rules from `.github/instructions/cp.shell.instructions.md` (4-space indentation, 80-char line length, `[[ ]]` conditionals, `"${var}"` quoting)
- [ ] T021 Run quickstart.md validation: walk through all three workflow examples (non-fork, clone-from-fork, clone-from-main-with-fork) and verify verbose output matches the output contract from contracts/script-interface.md

---

## Dependencies and Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Phase 2 — delivers MVP
- **US2 (Phase 4)**: Depends on Phase 2 — can run in parallel with US1 but builds on `create_pr` from US1
- **US3 (Phase 5)**: Depends on Phase 2 and US1 (extends `gather_diff_context` and `generate_pr_content`)
- **US4 (Phase 6)**: Depends on Phase 2 and US1 (extends `validate_preconditions`)
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Start after Phase 2 — no dependencies on other stories. Delivers the core non-fork workflow.
- **User Story 2 (P1)**: Start after Phase 2 — extends `create_pr` from US1 for fork path. Independently testable with any fork repo.
- **User Story 3 (P2)**: Start after US1 — extends `gather_diff_context` and `generate_pr_content`. Independently testable by adding a PR template.
- **User Story 4 (P2)**: Start after US1 — extends `validate_preconditions`. Independently testable by simulating pre-condition failures.

### Within Each User Story

- Functions that are independent of each other are marked [P]
- Core functions before orchestration (e.g., implement functions before wiring `main`)
- Story complete before moving to next priority

### Parallel Opportunities

- T003 (`get_remote_owner`) can be implemented in parallel with T002 (`validate_prerequisites`)
- T007 (`fetch_default_branch`) can be implemented in parallel with T006 (`validate_preconditions`)
- T014 (`find_pr_template`) can be implemented in parallel with other US3 tasks
- T019 and T020 (shellcheck, formatting) can run in parallel

---

## Parallel Example: User Story 1

```text
# These functions are independent and can be implemented in parallel:
T007: "Implement fetch_default_branch function in create-pr.sh"
T006: "Implement validate_preconditions function in create-pr.sh"

# Then sequential (depends on above):
T008: "Implement gather_diff_context function in create-pr.sh"
T009: "Implement generate_pr_content function in create-pr.sh"
T010: "Implement create_pr function in create-pr.sh"
T011: "Wire up main function in create-pr.sh"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup — script skeleton
2. Complete Phase 2: Foundational — tool checks, remote detection, default branch
3. Complete Phase 3: User Story 1 — non-fork PR creation
4. **STOP AND VALIDATE**: Test with a pushed feature branch in a non-forked repository
5. Script is usable for the most common PR workflow

### Incremental Delivery

1. Setup + Foundational → Script skeleton with shared functions
2. Add User Story 1 → Non-fork PR creation works → **MVP ready**
3. Add User Story 2 → Fork PR creation works → Both P1 stories complete
4. Add User Story 3 → PR template support → Better description quality
5. Add User Story 4 → Enhanced error messages → Better developer experience
6. Polish → Linting, formatting, validation → Production quality

### Single-File Consideration

All tasks modify `create-pr.sh`. True parallelism is limited to adding independent functions simultaneously. The recommended execution is sequential within each phase, parallelizing only where functions are genuinely independent (marked [P]).
