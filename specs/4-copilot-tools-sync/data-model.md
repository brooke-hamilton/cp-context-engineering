# Data Model: Copilot Tools Sync VS Code Extension

**Feature**: Copilot Tools Sync VS Code Extension
**Spec Directory**: `specs/4-copilot-tools-sync`
**Date**: February 14, 2026

## Entities

This extension operates on transient, in-memory data during a sync operation. There is no persistent storage beyond writing files to the local filesystem. All entities exist only for the duration of a single sync invocation.

---

### 1. Sync Configuration

The resolved configuration for a sync operation, combining extension settings and defaults.

| Field | Type | Description |
| --- | --- | --- |
| `repository` | string | GitHub `owner/repo` identifier (e.g., `brooke-hamilton/cp-context-engineering`) |
| `owner` | string | Parsed repository owner |
| `repo` | string | Parsed repository name |
| `filePrefix` | string | Fixed prefix for matching files (`cp.`), not configurable in v1 |

**Validation Rules**:

- `repository` must match the pattern `owner/repo` (non-empty owner and repo separated by `/`)
- `filePrefix` is always `cp.` (hardcoded)

---

### 2. Source Directory

A directory in the source GitHub repository that contains Copilot customization files.

| Field | Type | Description |
| --- | --- | --- |
| `remotePath` | string | Path in the repository (e.g., `.github/agents/`) |
| `localSubdir` | string | Corresponding subdirectory in the user profile (`agents/`, `instructions/`, `prompts/`) |
| `fileType` | enum | `agent`, `instruction`, `prompt` |

**Fixed Mapping**:

| Remote Path | Local Subdirectory | File Type |
| --- | --- | --- |
| `.github/agents/` | `agents/` | agent |
| `.github/instructions/` | `instructions/` | instruction |
| `.github/prompts/` | `prompts/` | prompt |

---

### 3. Remote File Entry

A file listed in a GitHub repository directory via the Contents API.

| Field | Type | Description |
| --- | --- | --- |
| `name` | string | File name (e.g., `cp.markdown.instructions.md`) |
| `path` | string | Full path in the repository |
| `type` | enum | `file` or `dir` (only `file` entries are processed) |
| `downloadUrl` | string | Direct URL to download raw file content |
| `size` | integer | File size in bytes |
| `matchesPrefix` | boolean | Whether `name` starts with `cp.` |

**Validation Rules**:

- Only entries with `type === "file"` are processed
- Only entries where `name` starts with `cp.` are synced
- `downloadUrl` must be non-null (GitHub API returns null for files > 100MB; unlikely for `.md` files)

---

### 4. User Profile Paths

The resolved local filesystem paths where synced files are written.

| Field | Type | Description |
| --- | --- | --- |
| `userDataDir` | string | Base VS Code user data directory (derived from `globalStorageUri`) |
| `agentsDir` | string | `{userDataDir}/agents/` |
| `instructionsDir` | string | `{userDataDir}/instructions/` |
| `promptsDir` | string | `{userDataDir}/prompts/` |

**Platform Examples**:

| OS | `userDataDir` |
| --- | --- |
| Linux | `~/.config/Code/User/` |
| macOS | `~/Library/Application Support/Code/User/` |
| Windows | `%APPDATA%\Code\User\` |

---

### 5. Sync Result

The outcome of a single sync operation.

| Field | Type | Description |
| --- | --- | --- |
| `totalFiles` | integer | Total number of "cp."-prefixed files found across all directories |
| `successCount` | integer | Number of files successfully written |
| `failedCount` | integer | Number of files that failed to sync |
| `failures` | array | List of `{fileName, error}` for each failed file |
| `status` | enum | `success`, `partial`, `error` |

**State Transitions**:

```mermaid
stateDiagram-v2
    [*] --> Idle : Extension loaded
    Idle --> Syncing : Command invoked
    Syncing --> Success : All files synced
    Syncing --> Partial : Some files failed
    Syncing --> Error : Sync failed entirely
    Success --> Idle : Notification shown
    Partial --> Idle : Warning shown
    Error --> Idle : Error shown
    Idle --> Blocked : Command invoked during sync
    Blocked --> Idle : Warning shown
```

---

## Entity Relationships

```mermaid
erDiagram
    SYNC_CONFIG ||--|{ SOURCE_DIRECTORY : defines
    SOURCE_DIRECTORY ||--o{ REMOTE_FILE_ENTRY : contains
    SOURCE_DIRECTORY ||--|| USER_PROFILE_PATHS : maps-to
    REMOTE_FILE_ENTRY }|--|| SYNC_RESULT : contributes-to

    SYNC_CONFIG {
        string repository
        string owner
        string repo
        string filePrefix
    }
    SOURCE_DIRECTORY {
        string remotePath
        string localSubdir
        enum fileType
    }
    REMOTE_FILE_ENTRY {
        string name
        string path
        string downloadUrl
        boolean matchesPrefix
    }
    USER_PROFILE_PATHS {
        string userDataDir
        string agentsDir
        string instructionsDir
        string promptsDir
    }
    SYNC_RESULT {
        integer totalFiles
        integer successCount
        integer failedCount
        enum status
    }
```

## Sync Execution Flow

```mermaid
flowchart TD
    A[User invokes 'Sync Copilot Tools'] --> B{Already syncing?}
    B -->|Yes| B1[Show warning: sync in progress]
    B1 --> Z[End]
    B -->|No| C[Set syncing flag]
    C --> D[Read configuration]
    D --> E[Resolve user profile paths]
    E --> F[For each source directory]
    F --> G["Fetch directory listing from GitHub API"]
    G --> H{API response OK?}
    H -->|No| I[Record directory error]
    H -->|Yes| J["Filter files by 'cp.' prefix"]
    J --> K{Any matching files?}
    K -->|No| L[Skip directory]
    K -->|Yes| M[For each matching file]
    M --> N[Download file content]
    N --> O{Download OK?}
    O -->|No| P[Record file failure]
    O -->|Yes| Q[Ensure destination directory exists]
    Q --> R[Write file to user profile]
    R --> S[Increment success count]
    P --> T{More files?}
    S --> T
    T -->|Yes| M
    T -->|No| U{More directories?}
    L --> U
    I --> U
    U -->|Yes| F
    U -->|No| V{Any successes?}
    V -->|All succeeded| W["Show info: N files synced"]
    V -->|Some failed| X["Show warning: N synced, M failed"]
    V -->|All failed| Y["Show error: sync failed"]
    W --> Z2[Clear syncing flag]
    X --> Z2
    Y --> Z2
    Z2 --> Z
```
