# Feature Specification: Copilot Tools Sync VS Code Extension

**Spec Directory**: `specs/4-copilot-tools-sync`
**Created**: 2026-02-14
**Status**: Draft
**Input**: User description: "VS Code plugin with a single command 'sync Copilot tools' that fetches files prefixed with 'cp.' from a GitHub repository and copies them into the user's VS Code profile folder for agents, instructions, and prompts."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Sync Copilot Tools from GitHub (Priority: P1)

A user wants to keep their personal VS Code Copilot customization files (agents, instructions, and prompts) up to date with the latest versions published in a shared GitHub repository. They open VS Code, run the "Sync Copilot Tools" command from the command palette, and the extension fetches all files starting with "cp." from the repository's `.github/agents/`, `.github/instructions/`, and `.github/prompts/` directories and copies them into the corresponding user-level profile directories in VS Code, overwriting any existing files with the same names.

**Why this priority**: This is the core and only feature of the extension. Without it, the extension has no purpose.

**Independent Test**: Can be fully tested by running the command and verifying that the matching files appear in the user's VS Code profile directories with content identical to the source repository.

**Acceptance Scenarios**:

1. **Given** the user has VS Code open with the extension installed, **When** they run the "Sync Copilot Tools" command from the command palette, **Then** all "cp."-prefixed agent, instruction, and prompt files from the configured GitHub repository are copied into the user's VS Code profile directories for agents, instructions, and prompts respectively.
2. **Given** the user already has older versions of "cp."-prefixed files in their profile, **When** they run the "Sync Copilot Tools" command, **Then** the existing files are overwritten with the latest versions from the repository.
3. **Given** the user runs the command successfully, **When** the sync completes, **Then** the user sees a confirmation notification indicating how many files were synced. No progress indicator is shown during the operation.

---

### User Story 2 - Handle Sync Errors Gracefully (Priority: P2)

A user runs the "Sync Copilot Tools" command but the sync fails because of a network issue, an unreachable repository, or another error. The extension displays a clear error message explaining what went wrong so the user can take corrective action.

**Why this priority**: Error handling ensures trust and usability. Users need to know when something goes wrong and why.

**Independent Test**: Can be tested by simulating network failure or an invalid repository URL and verifying the error notification appears.

**Acceptance Scenarios**:

1. **Given** the user runs the command and the repository is unreachable, **When** the sync attempt fails, **Then** the user sees an error notification with a meaningful message explaining the failure.
2. **Given** the user runs the command and some files fail to sync while others succeed, **When** the operation completes, **Then** the user sees a summary indicating which files succeeded and which failed.

---

### User Story 3 - Configure Source Repository (Priority: P3)

A user wants to sync Copilot tools from a different GitHub repository than the default. They update the extension's settings to point to their preferred repository URL, and subsequent sync commands pull files from that repository instead.

**Why this priority**: Configurability allows the extension to be reused across teams or for different tool sets. The default value covers the primary use case, making this a nice-to-have.

**Independent Test**: Can be tested by changing the repository URL in settings and verifying the sync pulls from the new repository.

**Acceptance Scenarios**:

1. **Given** the user has changed the source repository URL in the extension settings, **When** they run the "Sync Copilot Tools" command, **Then** files are fetched from the configured repository instead of the default.
2. **Given** the user has not changed any settings, **When** they run the "Sync Copilot Tools" command, **Then** files are fetched from the default repository (`brooke-hamilton/cp-context-engineering`).

---

### Edge Cases

- What happens when the repository contains no files matching the "cp." prefix? The user sees a notification indicating that no matching files were found.
- What happens when the user-level profile directories for agents, instructions, or prompts do not yet exist? The extension creates the necessary directories before copying files.
- What happens when a file in the repository is deleted between syncs? The extension only copies files that exist in the repository; it does not delete local files that are no longer present in the source. (Sync is additive/overwrite only, not a mirror.)
- What happens when the user runs the command while a sync is already in progress? The extension prevents concurrent sync operations and notifies the user that a sync is already running.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The extension MUST register a single command titled "Sync Copilot Tools" accessible from the VS Code command palette.
- **FR-002**: The extension MUST fetch the file listing from the configured GitHub repository's default branch.
- **FR-003**: The extension MUST identify all files with names starting with "cp." in the repository's `.github/agents/`, `.github/instructions/`, and `.github/prompts/` directories.
- **FR-004**: The extension MUST copy each identified file into the corresponding user-level VS Code profile directory for agents, instructions, and prompts, preserving file names.
- **FR-005**: The extension MUST overwrite existing files in the destination directories when files with the same name already exist.
- **FR-006**: The extension MUST create destination directories if they do not already exist.
- **FR-007**: The extension MUST display a notification upon successful completion, including the count of files synced.
- **FR-008**: The extension MUST display an error notification if the sync fails, with a meaningful description of the failure.
- **FR-009**: The extension MUST provide a configurable setting for the source GitHub repository, defaulting to `brooke-hamilton/cp-context-engineering`.
- **FR-010**: The extension MUST work with public GitHub repositories without requiring authentication, using the GitHub REST API (Contents API) for unauthenticated access.
- **FR-011**: The extension MUST NOT delete any local files that are not present in the source repository. Only files fetched from the repository are written; existing local files with different names are left untouched.
- **FR-012**: The extension MUST prevent concurrent execution of the sync command. If the command is invoked while a sync is already in progress, the user is notified and the duplicate invocation is ignored.

### Key Entities

- **Source Repository**: A public GitHub repository containing Copilot customization files organized under `.github/agents/`, `.github/instructions/`, and `.github/prompts/`.
- **Copilot Tool File**: A file with a name starting with "cp." located in one of the three customization directories (agents, instructions, prompts).
- **User Profile Directory**: The VS Code user-level directory where Copilot customization files are stored, varying by operating system.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can sync all "cp."-prefixed Copilot tool files from a GitHub repository to their local VS Code profile in a single command invocation without manual file copying.
- **SC-002**: The sync operation completes within 30 seconds under normal network conditions.
- **SC-003**: 100% of "cp."-prefixed files in the source repository's agents, instructions, and prompts directories are correctly copied to the corresponding local directories after a successful sync.
- **SC-004**: Users receive clear feedback (success or failure notification) after every sync attempt.
- **SC-005**: The extension works across all operating systems supported by VS Code (Windows, macOS, Linux) without additional user configuration.

## Clarifications

### Session 2026-02-14

- Q: What progress feedback should the user see during sync? → A: No progress indicator; user sees only the final completion or error notification.
- Q: How should the extension access the GitHub repository? → A: Use the GitHub REST API (Contents API), unauthenticated, to list directories and download individual files.
- Q: Should the "cp." file prefix be configurable? → A: No. Fixed "cp." prefix only in v1; no configurability.

## Assumptions

- The source GitHub repository is public and accessible without authentication via the GitHub REST API.
- The unauthenticated GitHub API rate limit (60 requests/hour per IP) is sufficient for typical usage since each sync requires only a few API calls (one per directory listing plus one per file).
- The repository follows the standard `.github/` directory structure with `agents/`, `instructions/`, and `prompts/` subdirectories.
- The "cp." prefix convention is fixed for this extension's initial version; prefix configurability may be added in a future iteration.
- The sync is one-directional: from the remote repository to the local user profile. Local changes are overwritten without warning.
- The extension targets the latest stable VS Code version and its corresponding extension API.

## Out of Scope

- Syncing files that do not start with the "cp." prefix.
- Two-way synchronization or conflict resolution.
- Support for private repositories or authenticated access.
- Any user interface elements beyond the command palette entry and notifications.
- Automatic or scheduled syncing; the user must manually invoke the command.
- Deleting local files that are no longer present in the source repository.
