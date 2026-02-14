# Implementation Plan: Copilot Tools Sync VS Code Extension

**Spec Directory**: `specs/4-copilot-tools-sync` | **Date**: February 14, 2026 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/4-copilot-tools-sync/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command.

## Summary

Create a VS Code extension with a single command "Sync Copilot Tools" that fetches files prefixed with "cp." from a configurable public GitHub repository's `.github/agents/`, `.github/instructions/`, and `.github/prompts/` directories and copies them into the user's VS Code profile directories. The extension uses the GitHub REST API (Contents API) for unauthenticated directory listing and file downloads, writes files via the `vscode.workspace.fs` API, and provides notification-based feedback on completion or failure.

## Technical Context

**Language/Version**: TypeScript 5.x
**Primary Dependencies**: VS Code Extension API, Node.js `https` module, `@vscode/vsce` (packaging)
**Storage**: Local filesystem (VS Code user profile directories)
**Testing**: Manual validation via side-loaded VSIX
**Target Platform**: VS Code on Windows, macOS, Linux (Stable and Insiders)
**Project Type**: Single VS Code extension
**Performance Goals**: Sync completes within 30 seconds under normal network conditions (SC-002)
**Constraints**: Unauthenticated GitHub API rate limit (60 requests/hour per IP); side-loaded only, not published to marketplace
**Scale/Scope**: Single user, ~6 files across 3 directories per sync (~9 API requests)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Documentation-First ✓ PASS

This feature specification, research document, data model, contracts, and quickstart all exist as markdown documents before any implementation code. The VS Code extension will be created only after planning is complete.

### Principle II: Mermaid Diagrams for Visual Communication ✓ PASS

Data model includes:

- State diagram for sync result lifecycle
- Entity relationship diagram for sync entities
- Flowchart for full sync execution flow

Quickstart includes:

- Sync flow diagram showing source-to-destination mapping
- Decision flowchart for sync behavior

### Principle III: Evidence-Based Recommendations ✓ PASS

Research document sources all decisions from:

- VS Code Extension API documentation (`globalStorageUri`, `workspace.fs`, command registration)
- GitHub REST API documentation (Contents endpoint, rate limiting)
- Node.js documentation (`https` module)
- VS Code extension packaging documentation (`@vscode/vsce`)

### Principle IV: Practical, Actionable Guidance ✓ PASS

Quickstart provides:

- 5-minute setup instructions with exact commands
- Troubleshooting table with symptoms, causes, and fixes
- Configuration instructions with JSON example
- User profile directory locations by OS

### Principle V: Spec Kit as Living Example ✓ PASS

This extension syncs Copilot customization files from this very repository. It demonstrates a practical context engineering workflow: users maintain "cp."-prefixed files in a shared repository and distribute them to their local VS Code installations via a single command.

### Principle VI: Iterative Development Over Perfection ✓ PASS

User stories are prioritized:

- P1: Core sync from GitHub to local profile (sole purpose of the extension)
- P2: Error handling and graceful failures (important but secondary)
- P3: Configurable source repository (nice-to-have, default covers primary use case)

### Git Operations Disabled ✓ PASS

This plan works on the main branch. No feature branch creation required per constitution.

### Deliverable Category 5: VS Code Extension ✓ PASS

Constitution explicitly defines "VS Code Extension" as a deliverable category for "privately used VS Code extension for personal workflow automation" that is "NOT published to any marketplace" and is "side-loaded for private use only." This extension matches exactly.

### Output Format ✓ PASS

All planning outputs are markdown documents. The extension source code (TypeScript) will be created during implementation, not during planning.

**GATE RESULT**: ✓ ALL CHECKS PASS — Proceed with implementation planning

## Project Structure

### Documentation (this feature)

```text
specs/4-copilot-tools-sync/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output - Research findings
├── data-model.md        # Phase 1 output - Entity definitions
├── quickstart.md        # Phase 1 output - Quick reference
├── contracts/           # Phase 1 output - Extension interface contract
│   └── extension-interface.md
├── spec.md              # Feature specification
├── tasks.md             # Phase 2 output (NOT created by /speckit.plan)
└── checklists/
    └── requirements.md  # Requirements checklist
```

### Source Code (repository root)

```text
extensions/copilot-tools-sync/
├── package.json          # Extension manifest (name, commands, configuration)
├── tsconfig.json         # TypeScript compiler configuration
├── .vscodeignore         # Files excluded from VSIX package
├── README.md             # Extension-specific documentation
├── src/
│   ├── extension.ts      # Entry point (activate/deactivate, command registration)
│   ├── sync.ts           # Core sync orchestration logic
│   ├── github-api.ts     # GitHub REST API client (list directories, download files)
│   └── profile-paths.ts  # VS Code user profile directory resolution
└── out/                  # Compiled JavaScript (gitignored)
```

**Structure Decision**: Single VS Code extension project under `extensions/copilot-tools-sync/`. The `extensions/` parent directory allows for future extensions without cluttering the repository root. The `src/` directory follows standard VS Code extension conventions with four focused modules: entry point, sync orchestration, GitHub API client, and profile path resolution.

## Complexity Tracking

> **No violations — this section not required**

All constitution checks passed. The extension is a focused, single-command tool with minimal dependencies (VS Code API and Node.js built-in `https`).

---

## Post-Phase 1 Constitution Re-Evaluation

<!-- markdownlint-disable MD036 -->
*Completed after Phase 0 research and Phase 1 design artifacts generated*

### Principle I: Documentation-First ✓ CONFIRMED

**Status**: All Phase 0 and Phase 1 artifacts are documentation:

- research.md: 7 research areas with decisions, rationale, alternatives, and sources
- data-model.md: 5 entities with fields, validation rules, and mermaid diagrams
- contracts/extension-interface.md: Full module contracts with inputs, outputs, and error messages
- quickstart.md: User-focused quick reference with setup, troubleshooting, and sync behavior

**Evidence**: No code generated. All deliverables are specifications and documentation.

### Principle II: Mermaid Diagrams for Visual Communication ✓ CONFIRMED

**Status**: Multiple mermaid diagrams across artifacts:

- data-model.md: Sync result state diagram, entity relationship diagram, execution flowchart
- quickstart.md: Source-to-destination mapping diagram, sync behavior flowchart

**Evidence**: Complex relationships (sync lifecycle, entity relationships, execution flow) are visualized.

### Principle III: Evidence-Based Recommendations ✓ CONFIRMED

**Status**: All recommendations grounded in research:

- research.md: VS Code API patterns verified against documentation
- research.md: GitHub Contents API endpoint documented with response format
- research.md: Node.js `https` module usage documented with code examples
- research.md: `vscode.workspace.fs` recommended for remote development compatibility

**Evidence**: Every technical decision links to API documentation or verified patterns.

### Principle IV: Practical, Actionable Guidance ✓ CONFIRMED

**Status**: Implementation focus throughout:

- quickstart.md: 5-minute setup with exact terminal commands
- quickstart.md: Troubleshooting table with 6 common issues and fixes
- contracts/extension-interface.md: Exact notification messages for each outcome
- data-model.md: Field-level validation rules for each entity

**Evidence**: Developer can understand the full extension behavior from documentation alone.

### Principle V: Spec Kit as Living Example ✓ CONFIRMED

**Status**: This extension directly supports the context engineering workflow:

- The "cp."-prefixed files in this repository ARE the Copilot tools
- The extension distributes them to the user's VS Code profile
- Demonstrates the "shared repository → local tools" context engineering pattern

**Evidence**: Feature is intrinsically tied to the repository's educational mission.

### Principle VI: Iterative Development Over Perfection ✓ CONFIRMED

**Status**: Prioritized delivery:

- P1: Core sync can be implemented and used immediately
- P2: Error handling adds robustness incrementally
- P3: Repository configuration enables reuse across teams
- Extension is fully usable after P1 implementation alone

**Evidence**: Each priority level is independently valuable and testable.

### Git Operations Disabled ✓ CONFIRMED

**Status**: All planning completed on main branch. No git operations performed.

### Deliverable Category 5 ✓ CONFIRMED

**Status**: Extension is designed for side-loading only. No marketplace publishing infrastructure.

**GATE RESULT**: ✓ ALL CHECKS PASS — Ready for Phase 2 task generation

---

## Artifacts Generated

| Artifact | Path | Purpose |
| --- | --- | --- |
| Research | [research.md](research.md) | Technology decisions and API reference |
| Data Model | [data-model.md](data-model.md) | Entity definitions, state diagrams, execution flow |
| Contracts | [contracts/extension-interface.md](contracts/extension-interface.md) | Module signatures, notification messages, HTTP contract |
| Quickstart | [quickstart.md](quickstart.md) | User quick reference with setup and troubleshooting |
| This Plan | [plan.md](plan.md) | Implementation planning |

---

## Next Steps

1. Run `/speckit.tasks` to generate Phase 2 task breakdown
2. Scaffold the `extensions/copilot-tools-sync/` project with `package.json` and `tsconfig.json`
3. Implement `profile-paths.ts` (user profile directory resolution)
4. Implement `github-api.ts` (GitHub Contents API client)
5. Implement `sync.ts` (core sync orchestration)
6. Implement `extension.ts` (command registration and activation)
7. Package with `vsce package` and test side-loaded installation
8. Test on Linux, macOS, and Windows
