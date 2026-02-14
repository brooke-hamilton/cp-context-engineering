# Implementation Plan: PR Creation Shell Script

**Spec Directory**: `specs/3-pr-creation-script` | **Date**: February 14, 2026 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/3-pr-creation-script/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command.

## Summary

Create a standalone Bash script (`create-pr.sh`) at the repository root that automates GitHub pull request creation. The script validates pre-conditions (branch state, uncommitted changes, pushed commits), auto-detects fork configurations from git remotes, gathers diffs and commit logs, uses the GitHub Copilot CLI (`copilot`) to generate a PR title and description in a single invocation, and creates the PR via `gh pr create`. No command-line arguments, no interactive prompts — the script infers everything from git state.

## Technical Context

**Language/Version**: Bash 5.3  
**Primary Dependencies**: GitHub CLI (`gh`), GitHub Copilot CLI (`copilot`), Git  
**Storage**: N/A  
**Testing**: Manual validation via script execution on test repositories  
**Target Platform**: Linux/macOS with bash-compatible shell  
**Project Type**: Single standalone script  
**Performance Goals**: N/A (interactive CLI tool, single invocation)  
**Constraints**: Requires `gh` CLI authenticated, `copilot` CLI on PATH and authenticated, git repository with at least one remote  
**Scale/Scope**: Single script, single PR per invocation

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Documentation-First ✓ PASS

This feature specification, research document, data model, contracts, and quickstart all exist as markdown documents before any implementation code. The `create-pr.sh` script will be created only after planning is complete.

### Principle II: Mermaid Diagrams for Visual Communication ✓ PASS

Data model includes:

- State diagram for fork detection algorithm
- Entity relationship diagram for script data flow
- Flowchart for full script execution flow

Quickstart includes:

- Workflow diagrams for all three remote configurations
- Decision tree for script behavior

### Principle III: Evidence-Based Recommendations ✓ PASS

Research document sources all decisions from:

- GitHub CLI documentation (`gh pr create` flags, `gh auth status` behavior)
- Git documentation (symbolic-ref, ls-remote, diff, status)
- Repository's existing shell script patterns (`.specify/scripts/bash/`)
- Existing prompt file (`.github/prompts/cp.create-pr.prompt.md`) as workflow reference

### Principle IV: Practical, Actionable Guidance ✓ PASS

Quickstart provides:

- 5-minute setup instructions
- Three common workflow examples with exact commands
- Decision tree for understanding script behavior
- Pre-condition error table with fixes

### Principle V: Spec Kit as Living Example ✓ PASS

This script automates a workflow that developers perform daily. It demonstrates converting a Copilot prompt (`.github/prompts/cp.create-pr.prompt.md`) into a standalone automation script — a practical context engineering pattern.

### Principle VI: Iterative Development Over Perfection ✓ PASS

User stories are prioritized:

- P1: Non-fork PR creation, fork PR creation (core workflows)
- P2: PR template support, pre-condition validation (important but secondary)

### Git Operations Disabled ✓ PASS

This plan works on the main branch. No feature branch creation required per constitution.

**GATE RESULT**: ✓ ALL CHECKS PASS — Proceed with implementation planning

## Project Structure

### Documentation (this feature)

```text
specs/3-pr-creation-script/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output - Research findings
├── data-model.md        # Phase 1 output - Entity definitions
├── quickstart.md        # Phase 1 output - Quick reference
├── contracts/           # Phase 1 output - Script interface contract
│   └── script-interface.md
├── spec.md              # Feature specification
├── tasks.md             # Phase 2 output (NOT created by /speckit.plan)
└── checklists/
    └── requirements.md  # Requirements checklist
```

### Source Code (repository root)

```text
create-pr.sh             # Standalone script (single file, no subdirectories)
```

**Structure Decision**: Single standalone script at the repository root. No `src/` or `tests/` directories — the script is self-contained with all functions defined inline. This matches the spec assumption: "The script is a standalone bash file located at `create-pr.sh` in the repository root."

## Complexity Tracking

> **No violations — this section not required**

All constitution checks passed. Feature is a single-file script with no external dependencies beyond `gh`, `copilot`, and `git`.

---

## Post-Phase 1 Constitution Re-Evaluation

<!-- markdownlint-disable MD036 -->
*Completed after Phase 0 research and Phase 1 design artifacts generated*

### Principle I: Documentation-First ✓ CONFIRMED

**Status**: All Phase 0 and Phase 1 artifacts are documentation:

- research.md: 10 research areas with decisions, rationale, alternatives, and sources
- data-model.md: 6 entities with fields, validation rules, and mermaid diagrams
- contracts/script-interface.md: Full function contracts with inputs, outputs, and error messages
- quickstart.md: User-focused quick reference with workflow examples

**Evidence**: No code generated. All deliverables are specifications and documentation.

### Principle II: Mermaid Diagrams for Visual Communication ✓ CONFIRMED

**Status**: Multiple mermaid diagrams across artifacts:

- data-model.md: Fork detection state diagram, entity relationship diagram, execution flowchart
- quickstart.md: Three workflow diagrams (one per remote config), decision tree

**Evidence**: Complex relationships (fork detection logic, data flow, execution states) are visualized.

### Principle III: Evidence-Based Recommendations ✓ CONFIRMED

**Status**: All recommendations grounded in research:

- research.md: `gh` CLI flags verified against documentation
- research.md: Git commands tested and documented with expected output
- research.md: Existing shell script patterns from `.specify/scripts/bash/` referenced
- research.md: Existing prompt file analyzed for workflow requirements

**Evidence**: Every technical decision links to CLI documentation or verified command output.

### Principle IV: Practical, Actionable Guidance ✓ CONFIRMED

**Status**: Implementation focus throughout:

- quickstart.md: Three workflow examples with copy-paste commands
- quickstart.md: Error table with specific remediation steps
- contracts/script-interface.md: Function signatures with exact error messages
- data-model.md: Validation rules for each entity

**Evidence**: Developer can understand the full script behavior from documentation alone.

### Principle V: Spec Kit as Living Example ✓ CONFIRMED

**Status**: This feature demonstrates the prompt-to-script conversion pattern:

- Original prompt: `.github/prompts/cp.create-pr.prompt.md`
- Target script: `create-pr.sh`
- Shows how AI agent prompts can be converted to deterministic automation

**Evidence**: Feature extends the educational mission with a practical automation example.

### Principle VI: Iterative Development Over Perfection ✓ CONFIRMED

**Status**: Prioritized delivery:

- P1: Core PR creation (non-fork and fork) can be implemented first
- P2: Template support and validation refinements add value incrementally
- Script is usable after P1 implementation alone

**Evidence**: Each priority level is independently valuable and testable.

### Git Operations Disabled ✓ CONFIRMED

**Status**: All planning completed on main branch. No git operations performed.

**GATE RESULT**: ✓ ALL CHECKS PASS — Ready for Phase 2 task generation

---

## Artifacts Generated

| Artifact | Path | Purpose |
|----------|------|---------|
| Research | [research.md](research.md) | Technology decisions and CLI command reference |
| Data Model | [data-model.md](data-model.md) | Entity definitions, state diagrams, execution flow |
| Contracts | [contracts/script-interface.md](contracts/script-interface.md) | Function signatures, error messages, output format |
| Quickstart | [quickstart.md](quickstart.md) | User quick reference with workflows |
| This Plan | [plan.md](plan.md) | Implementation planning |

---

## Next Steps

1. Run `/speckit.tasks` to generate Phase 2 task breakdown
2. Implement `create-pr.sh` following the contracts and shell instructions
3. Test with non-fork repository workflow
4. Test with clone-from-fork workflow
5. Test with clone-from-main-with-fork workflow
6. Test pre-condition validation error paths
7. Test PR template detection and Copilot CLI integration
