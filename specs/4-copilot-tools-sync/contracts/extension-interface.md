# Contracts: Copilot Tools Sync VS Code Extension

**Feature**: Copilot Tools Sync VS Code Extension
**Spec Directory**: `specs/4-copilot-tools-sync`
**Date**: February 14, 2026

## Extension Manifest Contract (package.json)

### Command Registration

```json
{
  "contributes": {
    "commands": [
      {
        "command": "copilotToolsSync.sync",
        "title": "Sync Copilot Tools"
      }
    ],
    "configuration": {
      "title": "Copilot Tools Sync",
      "properties": {
        "copilotToolsSync.repository": {
          "type": "string",
          "default": "brooke-hamilton/cp-context-engineering",
          "description": "GitHub repository (owner/repo) to sync Copilot tools from. Must be a public repository."
        }
      }
    }
  }
}
```

### Activation Events

```json
{
  "activationEvents": [
    "onCommand:copilotToolsSync.sync"
  ]
}
```

---

## Module Contracts

### `extension.ts` — Entry Point

#### `activate(context: ExtensionContext): void`

Registers the sync command and sets up the extension.

**Inputs**: `context` — VS Code `ExtensionContext` (provides `globalStorageUri`, `subscriptions`)
**Outputs**: None
**Side effects**: Registers `copilotToolsSync.sync` command, pushes disposable to `context.subscriptions`

#### `deactivate(): void`

No-op. No cleanup required.

---

### `sync.ts` — Core Sync Logic

#### `syncCopilotTools(context: ExtensionContext): Promise<void>`

Orchestrates the full sync operation.

**Inputs**: `context` — VS Code `ExtensionContext`
**Outputs**: None (communicates results via VS Code notifications)
**Side effects**:

- Reads extension configuration
- Makes HTTP requests to GitHub API
- Writes files to local filesystem
- Displays VS Code notifications

**Concurrency**: Guarded by module-level `isSyncing` boolean. Returns immediately with a warning notification if a sync is already in progress.

**Error contract**:

- Network errors → `showErrorMessage` with connectivity explanation
- API errors (403) → `showErrorMessage` with specific guidance
- Per-directory 404 → treated as empty directory (0 matching files), not an error
- Partial failures → `showWarningMessage` with success/failure counts
- All success → `showInformationMessage` with file count

**Notification Messages**:

| Condition | API | Message |
| --- | --- | --- |
| Sync in progress | `showWarningMessage` | `A sync is already in progress.` |
| All files synced | `showInformationMessage` | `Synced {n} Copilot tool files.` |
| No files found | `showInformationMessage` | `No Copilot tool files found matching the "cp." prefix.` |
| Some files failed | `showWarningMessage` | `Synced {n} files. {m} files failed to sync.` |
| Repository unreachable | `showErrorMessage` | `Sync failed: unable to reach repository "{owner}/{repo}".` |
| Repository not found | `showErrorMessage` | `Sync failed: repository "{owner}/{repo}" not found.` |
| Rate limit exceeded | `showErrorMessage` | `Sync failed: GitHub API rate limit exceeded. Try again later.` |
| Unknown error | `showErrorMessage` | `Sync failed: {error.message}` |

---

### `github-api.ts` — GitHub API Client

#### `listDirectoryFiles(owner: string, repo: string, path: string): Promise<GitHubFileEntry[]>`

Lists files in a GitHub repository directory.

**Inputs**:

- `owner` — repository owner (e.g., `brooke-hamilton`)
- `repo` — repository name (e.g., `cp-context-engineering`)
- `path` — directory path (e.g., `.github/agents`)

**Outputs**: Array of `GitHubFileEntry` objects

**Error behavior**: Throws on HTTP errors with descriptive messages

```typescript
interface GitHubFileEntry {
    name: string;
    path: string;
    type: 'file' | 'dir';
    size: number;
    download_url: string | null;
}
```

#### `downloadFileContent(url: string): Promise<Uint8Array>`

Downloads raw file content from a URL.

**Inputs**: `url` — download URL (from `GitHubFileEntry.download_url`)
**Outputs**: File content as `Uint8Array` (suitable for `vscode.workspace.fs.writeFile`)
**Error behavior**: Throws on HTTP errors or network failures

---

### `profile-paths.ts` — User Profile Directory Resolution

#### `resolveProfilePaths(context: ExtensionContext): ProfilePaths`

Resolves the user-level VS Code profile directories for Copilot customization files.

**Inputs**: `context` — VS Code `ExtensionContext`
**Outputs**: `ProfilePaths` object

```typescript
interface ProfilePaths {
    agents: vscode.Uri;
    instructions: vscode.Uri;
    prompts: vscode.Uri;
}
```

**Resolution logic**: Navigates from `context.globalStorageUri` up two directory levels to reach the `User/` directory, then appends each subdirectory name.

---

## Directory Mapping Contract

The extension maps source directories to destination directories using a fixed mapping:

| Source (GitHub) | Destination (User Profile) | File pattern |
| --- | --- | --- |
| `.github/agents/` | `{userDataDir}/agents/` | `cp.*` |
| `.github/instructions/` | `{userDataDir}/instructions/` | `cp.*` |
| `.github/prompts/` | `{userDataDir}/prompts/` | `cp.*` |

### Mapping Rules

- Only files with names starting with `cp.` are copied
- File names are preserved exactly (no renaming)
- Existing files with the same name are overwritten
- Destination directories are created if they do not exist
- Local files not present in the source repository are NOT deleted
- Files with `type !== "file"` are skipped (subdirectories are ignored)

---

## Configuration Contract

| Setting | Type | Default | Description |
| --- | --- | --- | --- |
| `copilotToolsSync.repository` | string | `brooke-hamilton/cp-context-engineering` | Source GitHub repository in `owner/repo` format |

### Validation

- If the value does not contain exactly one `/`, the extension shows an error: `Invalid repository format: "{value}". Expected "owner/repo".`
- Empty values fall back to the default

---

## HTTP Request Contract

All requests to the GitHub API follow this contract:

### Request Headers

| Header | Value |
| --- | --- |
| `User-Agent` | `copilot-tools-sync-vscode` |
| `Accept` | `application/vnd.github.v3+json` |

### Endpoints Used

| Operation | Method | URL |
| --- | --- | --- |
| List directory | GET | `https://api.github.com/repos/{owner}/{repo}/contents/{path}` |
| Download file | GET | `{download_url}` from directory listing |

### Error Mapping

| HTTP Status | Thrown Error |
| --- | --- |
| 200 | None (success) |
| 301 | Follow redirect |
| 403 | `GitHub API rate limit exceeded. Try again later.` |
| 404 (directory) | Treated as empty directory — returns empty array (non-fatal) |
| 404 (repository-level, all 3 dirs) | `Sync failed: repository "{owner}/{repo}" not found.` |
| 5xx | `GitHub API error: HTTP {statusCode}` |
| Network | `Unable to reach GitHub API. Check your network connection.` |
