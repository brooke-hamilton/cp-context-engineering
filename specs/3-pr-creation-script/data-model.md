# Data Model: PR Creation Shell Script

**Feature**: PR Creation Shell Script  
**Spec Directory**: `specs/3-pr-creation-script`  
**Date**: February 14, 2026

## Entities

This script operates on transient, in-memory data derived from git and CLI state. There is no persistent storage. All entities exist only for the duration of script execution.

---

### 1. Remote Configuration

The detected remote setup that determines fork status and PR target.

| Field | Type | Description |
|-------|------|-------------|
| `main_remote` | string | Remote pointing to the main repository (`origin` or `upstream`) |
| `fork_remote` | string | Remote pointing to the fork (empty if no fork) |
| `is_fork` | boolean | Whether a fork configuration was detected |
| `fork_owner` | string | GitHub owner of the fork remote (empty if no fork) |
| `main_repo` | string | `owner/repo` of the main repository |
| `detection_method` | enum | `upstream-remote`, `non-origin-branch`, `none` |

**State Transitions**:

```mermaid
stateDiagram-v2
    [*] --> CheckUpstream : Start detection
    CheckUpstream --> CloneFromFork : upstream remote exists
    CheckUpstream --> CheckNonOrigin : no upstream remote
    CheckNonOrigin --> CloneFromMain : branch on non-origin remote
    CheckNonOrigin --> NoFork : branch only on origin
    CloneFromFork --> [*] : main=upstream, fork=origin
    CloneFromMain --> [*] : main=origin, fork=detected remote
    NoFork --> [*] : main=origin, fork=none
```

---

### 2. Branch State

The current branch and its relationship to the default branch.

| Field | Type | Description |
|-------|------|-------------|
| `current_branch` | string | Name of the current git branch |
| `default_branch` | string | Name of the default branch (e.g., `main`, `master`) |
| `commit_count` | integer | Number of commits ahead of default branch |
| `is_pushed` | boolean | Whether the branch exists on at least one remote |
| `pushed_remote` | string | The remote where the branch has been pushed |

**Validation Rules**:

- `current_branch` must not equal `default_branch`
- `commit_count` must be greater than 0
- `is_pushed` must be true

---

### 3. Working Directory State

The cleanliness of the working directory.

| Field | Type | Description |
|-------|------|-------------|
| `has_unstaged` | boolean | Whether unstaged modifications exist |
| `has_staged` | boolean | Whether staged-but-uncommitted changes exist |
| `is_clean` | boolean | True when both `has_unstaged` and `has_staged` are false |

**Validation Rules**:

- `is_clean` must be true to proceed

---

### 4. Diff Context

The aggregated context passed to the Copilot CLI for content generation.

| Field | Type | Description |
|-------|------|-------------|
| `diff_stat` | string | Output of `git diff --stat` (file change summary) |
| `full_diff` | string | Output of `git diff` (full patch) |
| `commit_log` | string | Output of `git log --oneline` (commit messages) |
| `pr_template` | string | Contents of PR template file (empty if none found) |
| `template_path` | string | Path to the discovered PR template (empty if none) |

---

### 5. Generated PR Content

The title and description produced by the Copilot CLI.

| Field | Type | Description |
|-------|------|-------------|
| `title` | string | PR title (max 72 chars, noun phrase, capitalized first word) |
| `description` | string | PR description (markdown, follows template if available) |

**Validation Rules**:

- `title` must not be empty
- `description` must not be empty
- `title` is extracted from line 1 of Copilot CLI output
- `description` is extracted from line 3+ of Copilot CLI output

---

### 6. PR Result

The outcome of the PR creation.

| Field | Type | Description |
|-------|------|-------------|
| `pr_url` | string | URL of the created pull request |
| `base_branch` | string | The target branch (default branch of main repo) |
| `head_branch` | string | The source branch (with `owner:` prefix for forks) |
| `target_repo` | string | The `owner/repo` the PR targets |

---

## Entity Relationships

```mermaid
erDiagram
    REMOTE_CONFIG ||--|| BRANCH_STATE : determines
    BRANCH_STATE ||--|| WORKING_DIR_STATE : validates-before
    REMOTE_CONFIG ||--|| DIFF_CONTEXT : provides-comparison-target
    BRANCH_STATE ||--|| DIFF_CONTEXT : provides-commit-range
    DIFF_CONTEXT ||--|| GENERATED_CONTENT : input-to-copilot
    GENERATED_CONTENT ||--|| PR_RESULT : used-by-gh-create
    REMOTE_CONFIG ||--|| PR_RESULT : determines-head-base

    REMOTE_CONFIG {
        string main_remote
        string fork_remote
        boolean is_fork
        string fork_owner
    }
    BRANCH_STATE {
        string current_branch
        string default_branch
        integer commit_count
        boolean is_pushed
    }
    WORKING_DIR_STATE {
        boolean has_unstaged
        boolean has_staged
        boolean is_clean
    }
    DIFF_CONTEXT {
        string diff_stat
        string full_diff
        string commit_log
        string pr_template
    }
    GENERATED_CONTENT {
        string title
        string description
    }
    PR_RESULT {
        string pr_url
        string base_branch
        string head_branch
    }
```

## Script Execution Flow

```mermaid
flowchart TD
    A[Start] --> B[Validate Prerequisites]
    B --> B1[Check gh auth]
    B1 --> B2[Check copilot CLI]
    B2 --> C[Detect Remote Configuration]
    C --> D[Determine Default Branch]
    D --> E[Validate Pre-conditions]
    E --> E1{On default branch?}
    E1 -->|Yes| ERR1[ERROR: Must be on feature branch]
    E1 -->|No| E2{Clean working dir?}
    E2 -->|No| ERR2[ERROR: Commit changes first]
    E2 -->|Yes| E3{Commits ahead?}
    E3 -->|No| ERR3[ERROR: No changes for PR]
    E3 -->|Yes| E4{Branch pushed?}
    E4 -->|No| ERR4[ERROR: Push branch first]
    E4 -->|Yes| E5{PR exists?}
    E5 -->|Yes| ERR5[ERROR: PR already exists + URL]
    E5 -->|No| F[Fetch Default Branch]
    F --> G[Gather Diff Context]
    G --> G1[git diff --stat]
    G1 --> G2[git diff]
    G2 --> G3[git log]
    G3 --> G4[Find PR template]
    G4 --> H[Invoke Copilot CLI]
    H --> I[Parse Title + Description]
    I --> J[Create PR via gh]
    J --> K[Display PR URL]
    K --> L[End]
```
