# Research: Copilot Tools Sync VS Code Extension

<!-- markdownlint-disable MD024 -->

**Feature**: Copilot Tools Sync VS Code Extension
**Spec Directory**: `specs/4-copilot-tools-sync`
**Date**: February 14, 2026

## Research Tasks

This document consolidates research findings for building a VS Code extension that syncs "cp."-prefixed Copilot customization files from a GitHub repository to the user's local VS Code profile directories.

---

## 1. VS Code User Profile Directory Paths

### Decision

Derive the user data directory from `ExtensionContext.globalStorageUri` by navigating up two levels. This provides a reliable, cross-platform path to the `User/` directory where Copilot customization files are stored.

### User Data Directory by OS

| OS | VS Code Stable | VS Code Insiders |
| --- | --- | --- |
| Linux | `~/.config/Code/User/` | `~/.config/Code - Insiders/User/` |
| macOS | `~/Library/Application Support/Code/User/` | `~/Library/Application Support/Code - Insiders/User/` |
| Windows | `%APPDATA%\Code\User\` | `%APPDATA%\Code - Insiders\User\` |

### Copilot Customization Subdirectories

Within the `User/` directory, the Copilot customization files are stored in:

- `User/prompts/` — prompt files (`.prompt.md`)
- `User/agents/` — agent files (`.agent.md`)
- `User/instructions/` — instruction files (`.instructions.md`)

### Path Resolution Approach

```typescript
import * as vscode from 'vscode';
import * as path from 'path';

function getUserDataDir(context: vscode.ExtensionContext): string {
    // globalStorageUri is: <userDataDir>/User/globalStorage/<extension-id>/
    // Navigate up two levels to get <userDataDir>/User/
    const globalStoragePath = context.globalStorageUri.fsPath;
    return path.resolve(globalStoragePath, '..', '..');
}
```

### Rationale

- `globalStorageUri` is a stable VS Code API that works across all platforms and VS Code variants (Stable, Insiders, Remote)
- Navigating relative to a known API path avoids hardcoding platform-specific directory names
- This approach automatically handles VS Code Portable mode and custom installations

### Alternatives Considered

- **Hardcoded platform-specific paths**: Fragile, breaks with Portable mode, custom installs, and future VS Code changes. Rejected.
- **`vscode.env.appRoot`**: Points to the installation directory, not the user data directory. Requires separate mapping logic. Rejected.
- **Environment variables (`XDG_CONFIG_HOME`, `APPDATA`)**: Platform-specific and doesn't account for VS Code variant. Rejected.

### Sources

- VS Code API: `ExtensionContext.globalStorageUri`
- VS Code documentation: User data directory structure
- Observed VS Code Server Insiders paths in current environment

---

## 2. GitHub REST API Contents Endpoint

### Decision

Use the GitHub REST API Contents endpoint (`GET /repos/{owner}/{repo}/contents/{path}`) to list directory contents and download individual files. Use the `download_url` field from the listing response to fetch raw file content.

### API Endpoints

**List directory contents:**

```text
GET https://api.github.com/repos/{owner}/{repo}/contents/{path}
Accept: application/vnd.github.v3+json
```

Response (array of objects):

```json
[
  {
    "name": "cp.markdown.instructions.md",
    "path": ".github/instructions/cp.markdown.instructions.md",
    "type": "file",
    "size": 5234,
    "download_url": "https://raw.githubusercontent.com/{owner}/{repo}/{branch}/{path}"
  }
]
```

**Download file content:**

```text
GET {download_url}
```

Returns raw file content as plain text.

### Directories to Query

| Source Directory | Destination Subdirectory |
| --- | --- |
| `.github/agents/` | `User/agents/` |
| `.github/instructions/` | `User/instructions/` |
| `.github/prompts/` | `User/prompts/` |

### Rate Limiting

- Unauthenticated: 60 requests per hour per IP
- Each sync requires: 3 directory listings + N file downloads (one per matching file)
- With the current repository (~6 "cp."-prefixed files), a sync uses ~9 requests
- Well within the 60/hour limit for typical usage

### Error Handling

| HTTP Status | Meaning | Extension Response |
| --- | --- | --- |
| 200 | Success | Process response |
| 403 | Rate limit exceeded | Show error with rate limit info |
| 404 | Repository or path not found | Show error: repository or directory does not exist |
| Network error | No connectivity | Show error: unable to reach GitHub |

### Rationale

- The Contents API is the simplest way to list and download files from a public repository
- `download_url` provides a direct link to raw content, avoiding base64 decoding
- No authentication required for public repositories
- The API returns metadata (name, type, size) that enables filtering by prefix

### Alternatives Considered

- **GitHub Trees API**: Returns entire repository tree in one call. More efficient for large repos but more complex to parse. Rejected for simplicity — the extension only needs 3 specific directories.
- **Git clone / sparse checkout**: Requires git on the system, much heavier. Rejected.
- **Raw `githubusercontent.com` URLs**: Requires knowing exact filenames in advance. Cannot list directory contents. Rejected.

### Sources

- GitHub REST API documentation: Contents endpoint
- GitHub rate limiting documentation

---

## 3. VS Code Extension API Patterns

### Decision

Use standard VS Code Extension API patterns for command registration, configuration, and notifications. The extension activates on command invocation only (no startup activation).

### Command Registration

```typescript
// In package.json contributes
{
  "contributes": {
    "commands": [
      {
        "command": "copilotToolsSync.sync",
        "title": "Sync Copilot Tools"
      }
    ]
  }
}

// In extension.ts
export function activate(context: vscode.ExtensionContext) {
    const disposable = vscode.commands.registerCommand(
        'copilotToolsSync.sync',
        () => syncCopilotTools(context)
    );
    context.subscriptions.push(disposable);
}
```

### Configuration Contribution

```typescript
// In package.json contributes
{
  "contributes": {
    "configuration": {
      "title": "Copilot Tools Sync",
      "properties": {
        "copilotToolsSync.repository": {
          "type": "string",
          "default": "brooke-hamilton/cp-context-engineering",
          "description": "GitHub repository (owner/repo) to sync Copilot tools from"
        }
      }
    }
  }
}

// Reading configuration
const config = vscode.workspace.getConfiguration('copilotToolsSync');
const repo = config.get<string>('repository', 'brooke-hamilton/cp-context-engineering');
```

### Notifications

```typescript
// Success notification
vscode.window.showInformationMessage(`Synced ${count} Copilot tool files.`);

// Error notification
vscode.window.showErrorMessage(`Sync failed: ${error.message}`);

// Partial success
vscode.window.showWarningMessage(
    `Synced ${successCount} files. ${failCount} files failed.`
);
```

### Activation Events

```json
{
  "activationEvents": [
    "onCommand:copilotToolsSync.sync"
  ]
}
```

The extension only activates when the user invokes the command, keeping VS Code startup fast.

### Rationale

- `onCommand` activation is the most efficient — no unnecessary initialization
- Single command keeps the extension simple and focused
- VS Code notification API provides the right level of user feedback for this use case
- Configuration contribution makes the repository setting discoverable in VS Code Settings UI

### Sources

- VS Code Extension API documentation
- VS Code extension samples

---

## 4. VS Code Extension Packaging and Side-Loading

### Decision

Use `@vscode/vsce` to package the extension as a `.vsix` file. Include a Makefile target for building and installing. The extension is NOT published to the VS Code Marketplace.

### Build and Package

```bash
# Install packaging tool
npm install --save-dev @vscode/vsce

# Package into .vsix
npx vsce package

# Produces: copilot-tools-sync-0.0.1.vsix
```

### Side-Load Installation

```bash
# Install from command line
code --install-extension copilot-tools-sync-0.0.1.vsix

# Or via VS Code UI: Extensions → ... → Install from VSIX
```

### Project Setup

```json
// package.json (extension manifest)
{
  "name": "copilot-tools-sync",
  "displayName": "Copilot Tools Sync",
  "description": "Sync Copilot customization files from a GitHub repository",
  "version": "0.0.1",
  "publisher": "brooke-hamilton",
  "engines": { "vscode": "^1.100.0" },
  "categories": ["Other"],
  "main": "./out/extension.js"
}
```

### Rationale

- `vsce package` is the standard tool for creating VS Code extension packages
- Side-loading via `--install-extension` is documented and well-supported
- No need for marketplace publishing infrastructure per constitution (deliverable category 5)

### Alternatives Considered

- **Publishing to marketplace**: Out of scope — constitution specifies "private use, side-loaded only". Rejected.
- **Dev mode only (`F5` debugging)**: Doesn't persist between sessions. Insufficient for daily use. Rejected.

### Sources

- VS Code extension packaging documentation
- `@vscode/vsce` package documentation

---

## 5. Concurrency Control in VS Code Extensions

### Decision

Use a module-level boolean flag to prevent concurrent sync operations. Check the flag at command entry and display a notification if a sync is already running.

### Implementation

```typescript
let isSyncing = false;

async function syncCopilotTools(context: vscode.ExtensionContext): Promise<void> {
    if (isSyncing) {
        vscode.window.showWarningMessage('A sync is already in progress.');
        return;
    }

    isSyncing = true;
    try {
        // ... sync logic ...
    } finally {
        isSyncing = false;
    }
}
```

### Rationale

- VS Code extension host runs on a single thread (Node.js event loop), so a simple boolean is safe — no race conditions
- `try/finally` ensures the flag is always cleared, even on errors
- Simpler than mutex or semaphore patterns, which are unnecessary in a single-threaded environment

### Alternatives Considered

- **VS Code `CancellationToken`**: More complex, designed for long-running operations with cancellation support. Overkill for a brief sync. Rejected.
- **Disable command during sync**: Possible via `vscode.commands.executeCommand('setContext', ...)` but adds complexity for no real UX benefit beyond the notification. Rejected.

---

## 6. Node.js HTTP Client for VS Code Extensions

### Decision

Use Node.js built-in `https` module (via `https.get`) for GitHub API requests. Avoid third-party HTTP dependencies.

### Implementation Pattern

```typescript
import * as https from 'https';

function fetchJson(url: string): Promise<unknown> {
    return new Promise((resolve, reject) => {
        const options = {
            headers: {
                'User-Agent': 'copilot-tools-sync-vscode',
                'Accept': 'application/vnd.github.v3+json'
            }
        };
        https.get(url, options, (res) => {
            if (res.statusCode !== 200) {
                reject(new Error(`HTTP ${res.statusCode}`));
                res.resume();
                return;
            }
            let data = '';
            res.on('data', (chunk) => { data += chunk; });
            res.on('end', () => {
                resolve(JSON.parse(data));
            });
        }).on('error', reject);
    });
}
```

### Required Headers

| Header | Value | Purpose |
| --- | --- | --- |
| `User-Agent` | `copilot-tools-sync-vscode` | Required by GitHub API (requests without UA are rejected) |
| `Accept` | `application/vnd.github.v3+json` | Specify API version |

### Rationale

- `https` is built into Node.js — zero additional dependencies
- VS Code extensions run in Node.js, so all Node.js APIs are available
- The extension makes simple GET requests only; no need for a full HTTP client library
- Keeping dependencies minimal reduces extension size and supply chain risk

### Alternatives Considered

- **`node-fetch`**: Popular but adds a dependency. Rejected for minimalism.
- **`axios`**: Feature-rich but heavy for simple GET requests. Rejected.
- **VS Code's built-in fetch (global `fetch` in Node 18+)**: Available in newer Node.js versions but the VS Code extension host Node version varies. Using `https` module is safer for compatibility. Rejected for now.

---

## 7. File Writing and Directory Creation

### Decision

Use VS Code's `vscode.workspace.fs` API for file system operations instead of Node.js `fs` module. This ensures compatibility with VS Code's virtual file system layer and remote development scenarios.

### Implementation

```typescript
import * as vscode from 'vscode';

async function writeFile(
    filePath: vscode.Uri,
    content: Uint8Array
): Promise<void> {
    // Creates parent directories automatically
    await vscode.workspace.fs.createDirectory(
        vscode.Uri.joinPath(filePath, '..')
    );
    await vscode.workspace.fs.writeFile(filePath, content);
}
```

### Rationale

- `vscode.workspace.fs` works transparently with VS Code Remote (SSH, WSL, Containers)
- Automatically handles path normalization across platforms
- `createDirectory` is idempotent — safe to call even if directory exists
- Keeps the extension consistent with VS Code API conventions

### Alternatives Considered

- **Node.js `fs.mkdirSync` / `fs.writeFileSync`**: Works for local-only scenarios but breaks in Remote Development. Rejected.
- **Node.js `fs.promises`**: Same local-only limitation. Rejected.

### Sources

- VS Code API: `workspace.fs`

---

## Summary of Key Decisions

| Area | Decision | Confidence |
| --- | --- | --- |
| User profile paths | Derive from `globalStorageUri`, navigate up 2 levels | High |
| GitHub API | Contents API (`/repos/{owner}/{repo}/contents/{path}`) | High |
| HTTP client | Node.js built-in `https` module | High |
| Command registration | Single command, `onCommand` activation | High |
| Configuration | VS Code Settings API with default repository | High |
| Concurrency control | Module-level boolean flag with `try/finally` | High |
| File system operations | `vscode.workspace.fs` API | High |
| Packaging | `@vscode/vsce`, side-loaded VSIX | High |
| Notifications | `showInformationMessage` / `showErrorMessage` | High |
| Extension location | `extensions/copilot-tools-sync/` directory in repository | High |

---

## References

- VS Code Extension API documentation
- GitHub REST API: Contents endpoint
- VS Code extension packaging (`@vscode/vsce`)
- Node.js `https` module documentation
- VS Code Remote Development architecture
