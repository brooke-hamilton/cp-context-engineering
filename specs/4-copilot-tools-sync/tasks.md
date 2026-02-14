# Tasks: Copilot Tools Sync VS Code Extension

**Input**: Design documents from `/specs/4-copilot-tools-sync/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/extension-interface.md, quickstart.md

**Tests**: Not explicitly requested in the feature specification. Test tasks are omitted.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Extension root**: `extensions/copilot-tools-sync/`
- **Source files**: `extensions/copilot-tools-sync/src/`
- **Compiled output**: `extensions/copilot-tools-sync/out/` (gitignored)

## Environment Prerequisites

Verified on current machine (2026-02-14):

| Tool | Version |
| --- | --- |
| Node.js | v22.15.0 |
| npm | 10.9.2 |
| TypeScript | 5.9.2 |
| VS Code CLI | 1.109.3 |
| git | 2.53.0 |
| @vscode/vsce | 3.7.1 (via npx) |

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and VS Code extension scaffold

- [x] T001 Create extension directory structure at `extensions/copilot-tools-sync/`
- [x] T002 Create `extensions/copilot-tools-sync/package.json` with extension manifest (name `copilot-tools-sync`, displayName `Copilot Tools Sync`, publisher `brooke-hamilton`, version `0.0.1`, engines `{ "vscode": "^1.100.0" }`, main `./out/extension.js`, activationEvents `onCommand:copilotToolsSync.sync`, contributes for command `copilotToolsSync.sync` titled "Sync Copilot Tools", configuration contribution for `copilotToolsSync.repository` with type string and default `brooke-hamilton/cp-context-engineering`, scripts with `compile` as `tsc -p ./`, devDependencies for `@types/vscode`, `typescript`, and `@vscode/vsce`)
- [x] T003 [P] Create `extensions/copilot-tools-sync/tsconfig.json` with TypeScript compiler configuration (target ES2022, module commonjs, outDir `./out`, rootDir `./src`, strict true, esModuleInterop true, sourceMap true, exclude `node_modules` and `out`)
- [x] T004 [P] Create `extensions/copilot-tools-sync/.vscodeignore` to exclude `src/`, `tsconfig.json`, `node_modules/`, and non-essential files from VSIX package
- [x] T005 [P] Create `extensions/copilot-tools-sync/.gitignore` to ignore `out/`, `node_modules/`, and `*.vsix`
- [x] T006 Install npm dependencies by running `npm install` in `extensions/copilot-tools-sync/`

**Checkpoint**: Extension project scaffold is ready with all configuration files and dependencies installed

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core modules that ALL user stories depend on — GitHub API client, profile path resolution

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T007 [P] Implement `extensions/copilot-tools-sync/src/profile-paths.ts` — export `ProfilePaths` interface with `agents`, `instructions`, and `prompts` as `vscode.Uri` properties; export `resolveProfilePaths(context: ExtensionContext): ProfilePaths` function that derives user data directory from `context.globalStorageUri.fsPath` by navigating up 2 levels via `path.resolve(globalStoragePath, '..', '..')`, then returns URIs for `agents/`, `instructions/`, and `prompts/` subdirectories
- [x] T008 [P] Implement `extensions/copilot-tools-sync/src/github-api.ts` — export `GitHubFileEntry` interface (`name`, `path`, `type`, `size`, `download_url`); export `listDirectoryFiles(owner, repo, path): Promise<GitHubFileEntry[]>` using Node.js `https` module to GET `https://api.github.com/repos/{owner}/{repo}/contents/{path}` with headers `User-Agent: copilot-tools-sync-vscode` and `Accept: application/vnd.github.v3+json`, parse JSON response, throw descriptive errors for HTTP 403 (rate limit), 404 (not found), 5xx, and network failures; export `downloadFileContent(url): Promise<Uint8Array>` that GETs the URL, follows 301 redirects, and returns body as `Uint8Array`

**Checkpoint**: Foundation ready — profile path resolution and GitHub API client are independently functional

---

## Phase 3: User Story 1 — Sync Copilot Tools from GitHub (Priority: P1) MVP

**Goal**: User runs "Sync Copilot Tools" from the command palette and all `cp.`-prefixed files from the configured repository's `.github/agents/`, `.github/instructions/`, and `.github/prompts/` directories are copied into the corresponding user profile directories

**Independent Test**: Run the command and verify that matching files appear in the user's VS Code profile directories with content identical to the source repository

### Implementation for User Story 1

- [x] T009 [US1] Implement `extensions/copilot-tools-sync/src/sync.ts` — export `syncCopilotTools(context: ExtensionContext): Promise<void>` that: reads `copilotToolsSync.repository` config (default `brooke-hamilton/cp-context-engineering`), parses `owner/repo`, resolves profile paths via `resolveProfilePaths`, iterates over 3 source directory mappings (`.github/agents` → `agents`, `.github/instructions` → `instructions`, `.github/prompts` → `prompts`), calls `listDirectoryFiles` for each, filters entries where `name` starts with `cp.` and `type === "file"`, downloads each via `downloadFileContent`, ensures destination directory exists via `vscode.workspace.fs.createDirectory`, writes via `vscode.workspace.fs.writeFile`, tracks success count, shows `showInformationMessage("Synced {n} Copilot tool files.")` on success
- [x] T010 [US1] Implement `extensions/copilot-tools-sync/src/extension.ts` — export `activate(context: ExtensionContext)` that registers `copilotToolsSync.sync` command calling `syncCopilotTools(context)`, pushes disposable to `context.subscriptions`; export no-op `deactivate()`
- [x] T011 [US1] Compile the extension (`npm run compile`) and verify output files in `extensions/copilot-tools-sync/out/`
- [x] T012 [US1] Package as VSIX (`npx vsce package` in `extensions/copilot-tools-sync/`), install via `code --install-extension`, run "Sync Copilot Tools" from command palette, verify `cp.`-prefixed files appear in user profile directories

**Checkpoint**: User Story 1 is fully functional — core sync works end-to-end

---

## Phase 4: User Story 2 — Handle Sync Errors Gracefully (Priority: P2)

**Goal**: When sync fails due to network issues, unreachable repository, rate limiting, or partial file failures, the user sees a clear and actionable error or warning notification

**Independent Test**: Simulate failure conditions (invalid repo URL, disconnected network) and verify appropriate error notifications appear

### Implementation for User Story 2

- [x] T013 [US2] Add concurrency guard to `syncCopilotTools` in `extensions/copilot-tools-sync/src/sync.ts` — module-level `let isSyncing = false`, check at entry and show `showWarningMessage("A sync is already in progress.")` if true, wrap sync logic in `try/finally` to always clear flag
- [x] T014 [US2] Add error handling to `syncCopilotTools` in `extensions/copilot-tools-sync/src/sync.ts` — catch network errors → `showErrorMessage("Sync failed: unable to reach repository...")`, catch 404 → `showErrorMessage("Sync failed: repository not found...")`, catch 403 → `showErrorMessage("Sync failed: GitHub API rate limit exceeded...")`, catch unknown → `showErrorMessage("Sync failed: {error.message}")`
- [x] T015 [US2] Add partial failure handling to `extensions/copilot-tools-sync/src/sync.ts` — track `failedCount` and `failures` array alongside `successCount`, on partial failure show `showWarningMessage("Synced {n} files. {m} files failed to sync.")`, on total failure show `showErrorMessage`; when no files found show `showInformationMessage('No Copilot tool files found matching the "cp." prefix.')`
- [x] T016 [US2] Add repository format validation to `extensions/copilot-tools-sync/src/sync.ts` — validate configured value matches `owner/repo` format (non-empty owner and repo separated by `/`), show `showErrorMessage('Invalid repository format: "{value}". Expected "owner/repo".')` on invalid input, fall back to default on empty value
- [x] T017 [US2] Recompile, repackage VSIX, and manually validate error scenarios (invalid repository setting, network disconnect)

**Checkpoint**: User Story 2 complete — all error paths produce clear user-facing notifications

---

## Phase 5: User Story 3 — Configure Source Repository (Priority: P3)

**Goal**: User can change the source repository in VS Code settings and subsequent sync commands pull files from the configured repository

**Independent Test**: Change `copilotToolsSync.repository` setting to a different public repo with `cp.`-prefixed files, run sync, and verify files come from the new source

### Implementation for User Story 3

- [x] T018 [US3] Verify configuration contribution in `extensions/copilot-tools-sync/package.json` renders correctly in VS Code Settings UI under "Copilot Tools Sync", change `copilotToolsSync.repository` in settings to a different public repository, run sync, verify files fetched from the configured source
- [x] T019 [US3] Recompile and repackage VSIX for final configuration validation

**Checkpoint**: User Story 3 complete — repository is fully configurable via VS Code settings

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation and build integration

- [x] T020 [P] Create `extensions/copilot-tools-sync/README.md` with extension overview, installation instructions (build + side-load), usage (command palette), configuration (repository setting), and troubleshooting
- [x] T021 [P] Add Makefile targets at repository root `Makefile` for `build-extension` (`cd extensions/copilot-tools-sync && npm install && npm run compile`), `package-extension` (`cd extensions/copilot-tools-sync && npx vsce package`), and `install-extension` (`code --install-extension` on generated `.vsix`)
- [x] T022 Run quickstart.md validation — follow the 5-minute setup steps in `specs/4-copilot-tools-sync/quickstart.md` and verify the extension works end-to-end

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational phase completion
- **User Story 2 (Phase 4)**: Depends on User Story 1 (adds error handling to existing sync logic)
- **User Story 3 (Phase 5)**: Depends on User Story 1 (validates config reading already in sync.ts)
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) — no dependencies on other stories
- **User Story 2 (P2)**: Enhances User Story 1's `sync.ts` — must follow US1
- **User Story 3 (P3)**: Validates configuration in `sync.ts` — must follow US1, can run in parallel with US2

### Within Each User Story

- Core logic modules before entry point
- Compile and verify after implementation
- Package and validate before declaring story complete

### Parallel Opportunities

- T003, T004, T005 (Setup config files) can run in parallel
- T007, T008 (Foundational: profile-paths.ts, github-api.ts) can run in parallel — different files, no dependencies
- T020, T021 (Polish: README and Makefile) can run in parallel
- US2 and US3 can run in parallel after US1 (different concerns, but safer to run sequentially since both touch sync.ts)

---

## Parallel Example: Foundational Phase

```text
# Launch both foundational modules together (different files, no dependencies):
T007: "Implement profile path resolution in extensions/copilot-tools-sync/src/profile-paths.ts"
T008: "Implement GitHub API client in extensions/copilot-tools-sync/src/github-api.ts"
```

## Parallel Example: Setup Config Files

```text
# Launch all config files together (different files):
T003: "Create tsconfig.json"
T004: "Create .vscodeignore"
T005: "Create .gitignore"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T006)
2. Complete Phase 2: Foundational (T007–T008)
3. Complete Phase 3: User Story 1 (T009–T012)
4. **STOP and VALIDATE**: Install VSIX, run sync, verify files appear in profile directories
5. Extension is usable at this point for the primary use case

### Incremental Delivery

1. Complete Setup + Foundational → Project scaffold ready
2. Add User Story 1 → Test independently → MVP is functional
3. Add User Story 2 → Test error scenarios → Robust error handling
4. Add User Story 3 → Test config change → Fully configurable
5. Polish → Documentation and build automation

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story is independently completable and testable after its phase
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- The extension is side-loaded only (not published to marketplace)
- Total API requests per sync: ~9 (3 directory listings + ~6 file downloads), well within GitHub's 60/hour unauthenticated limit
