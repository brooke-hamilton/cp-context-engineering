# Quickstart: PR Creation Shell Script

**Feature**: PR Creation Shell Script  
**Spec Directory**: `specs/3-pr-creation-script`  
**Date**: February 14, 2026

## 5-Minute Setup

1. Ensure `gh` CLI is installed and authenticated:

   ```bash
   gh auth status
   ```

2. Ensure `copilot` CLI is on your PATH and authenticated:

   ```bash
   copilot --version
   ```

3. The script lives at repo root as `create-pr.sh`. No installation needed.

## Usage

```bash
# From the repo root, on a feature branch with pushed commits:
./create-pr.sh
```

No arguments. No flags. Everything is auto-detected.

## Common Workflows

### Non-fork repository

```mermaid
flowchart LR
    A[Feature branch] --> B[Commits pushed to origin]
    B --> C["./create-pr.sh"]
    C --> D[PR: origin/feature → origin/main]
```

```bash
git checkout -b my-feature
# ... make changes ...
git add . && git commit -m "Add feature"
git push origin my-feature
./create-pr.sh
```

### Fork (cloned from fork)

```mermaid
flowchart LR
    A[Feature branch] --> B[Commits pushed to origin/fork]
    B --> C["./create-pr.sh"]
    C --> D[PR: fork/feature → upstream/main]
```

```bash
# origin = your fork, upstream = main repo
git checkout -b my-feature
# ... make changes ...
git add . && git commit -m "Add feature"
git push origin my-feature
./create-pr.sh
# PR targets upstream/main from origin/my-feature
```

### Fork (cloned from main, fork added as remote)

```mermaid
flowchart LR
    A[Feature branch] --> B[Commits pushed to myfork remote]
    B --> C["./create-pr.sh"]
    C --> D[PR: myfork/feature → origin/main]
```

```bash
# origin = main repo, myfork = your fork
git remote add myfork https://github.com/you/repo.git
git checkout -b my-feature
# ... make changes ...
git add . && git commit -m "Add feature"
git push myfork my-feature
./create-pr.sh
# PR targets origin/main from myfork/my-feature
```

## Decision Tree: What Happens When You Run the Script

```mermaid
flowchart TD
    Start["./create-pr.sh"] --> Q1{gh + copilot installed<br/>and authenticated?}
    Q1 -->|No| E1[Exit with install/auth error]
    Q1 -->|Yes| Q2{upstream remote exists?}
    Q2 -->|Yes| Fork1["Clone-from-fork mode<br/>main=upstream, fork=origin"]
    Q2 -->|No| Q3{Branch on non-origin remote?}
    Q3 -->|Yes| Fork2["Clone-from-main mode<br/>main=origin, fork=detected"]
    Q3 -->|No| NoFork["No-fork mode<br/>main=origin"]
    Fork1 --> Validate
    Fork2 --> Validate
    NoFork --> Validate
    Validate[Validate pre-conditions] --> Q4{All pass?}
    Q4 -->|No| E2[Exit with specific error]
    Q4 -->|Yes| Generate[Generate title + description<br/>via Copilot CLI]
    Generate --> Create["gh pr create"]
    Create --> Done[Display PR URL]
```

## Pre-condition Errors and Fixes

| Error | What to do |
|-------|------------|
| "Cannot create PR from the default branch" | Switch to a feature branch: `git checkout -b my-feature` |
| "Uncommitted changes detected" | Commit your changes: `git add . && git commit -m "message"` |
| "No commits ahead" | Make and commit changes on your feature branch |
| "Branch has not been pushed" | Push your branch: `git push origin my-branch` |
| "PR already exists" | Visit the existing PR URL shown in the error |
| "Not authenticated to GitHub CLI" | Run `gh auth login` |
| "Copilot CLI not found" | Install the Copilot CLI and add to PATH |

## What Gets Generated

The Copilot CLI generates:

- **Title**: Noun phrase, max 72 characters, first word capitalized, no conventional commit prefixes
- **Description**: If a PR template exists, follows its structure (including checkboxes). Otherwise, includes summary, modified files list, and commit context.
