import * as vscode from 'vscode';
import { resolvePromptsPath } from './profile-paths';
import { listDirectoryFiles, downloadFileContent } from './github-api';

const DIR_MAPPINGS = [
    { remote: '.github/agents', local: 'agents', setting: 'chat.agentFilesLocations' },
    { remote: '.github/instructions', local: 'instructions', setting: 'chat.instructionsFilesLocations' },
    { remote: '.github/prompts', local: 'prompts', setting: 'chat.promptFilesLocations' },
] as const;

let isSyncing = false;

export async function syncCopilotTools(log: vscode.OutputChannel, context: vscode.ExtensionContext): Promise<void> {
    if (isSyncing) {
        vscode.window.showWarningMessage('A sync is already in progress.');
        return;
    }

    isSyncing = true;
    try {
        log.appendLine(`[${new Date().toISOString()}] Starting sync...`);
        const config = vscode.workspace.getConfiguration('copilotToolsSync');
        let repository = config.get<string>('repository', 'brooke-hamilton/cp-context-engineering');

        if (!repository) {
            repository = 'brooke-hamilton/cp-context-engineering';
        }

        const slashIndex = repository.indexOf('/');
        if (slashIndex <= 0 || slashIndex === repository.length - 1 || repository.indexOf('/', slashIndex + 1) !== -1) {
            vscode.window.showErrorMessage(`Invalid repository format: "${repository}". Expected "owner/repo".`);
            return;
        }

        const owner = repository.substring(0, slashIndex);
        const repo = repository.substring(slashIndex + 1);
        log.appendLine(`Repository: ${owner}/${repo}`);
        const promptsDir = resolvePromptsPath(context);
        log.appendLine(`Destination: ${promptsDir.fsPath}`);
        await vscode.workspace.fs.createDirectory(promptsDir);

        let successCount = 0;
        let failedCount = 0;
        const failures: { fileName: string; error: string }[] = [];

        for (const mapping of DIR_MAPPINGS) {
            let entries;
            try {
                entries = await listDirectoryFiles(owner, repo, mapping.remote);
            } catch (err) {
                const message = err instanceof Error ? err.message : String(err);
                if (message.includes('rate limit')) {
                    vscode.window.showErrorMessage('Sync failed: GitHub API rate limit exceeded. Try again later.');
                    return;
                }
                if (message.includes('Unable to reach')) {
                    vscode.window.showErrorMessage(`Sync failed: unable to reach repository "${owner}/${repo}".`);
                    return;
                }
                vscode.window.showErrorMessage(`Sync failed: ${message}`);
                return;
            }

            const matchingFiles = entries.filter(
                (e) => e.type === 'file' && e.name.startsWith('cp.') && e.download_url
            );

            if (matchingFiles.length === 0) {
                continue;
            }

            for (const file of matchingFiles) {
                try {
                    const content = await downloadFileContent(file.download_url!);
                    const destUri = vscode.Uri.joinPath(promptsDir, file.name);
                    await vscode.workspace.fs.writeFile(destUri, content);
                    successCount++;
                    log.appendLine(`  Synced: ${mapping.remote}/${file.name} -> ${destUri.fsPath}`);
                } catch (err) {
                    failedCount++;
                    const errorMsg = err instanceof Error ? err.message : String(err);
                    failures.push({ fileName: file.name, error: errorMsg });
                    log.appendLine(`  FAILED: ${mapping.remote}/${file.name} — ${errorMsg}`);
                }
            }
        }

        const showLog = 'Show Log';
        if (successCount === 0 && failedCount === 0) {
            log.appendLine('No files found matching the "cp." prefix.');
            const choice = await vscode.window.showInformationMessage(
                'No Copilot tool files found matching the "cp." prefix.', showLog);
            if (choice === showLog) { log.show(); }
        } else if (failedCount === 0) {
            await registerDiscoveryPaths(promptsDir);
            log.appendLine(`Sync complete: ${successCount} files synced.`);
            const choice = await vscode.window.showInformationMessage(
                `Synced ${successCount} Copilot tool files.`, showLog);
            if (choice === showLog) { log.show(); }
        } else if (successCount > 0) {
            await registerDiscoveryPaths(promptsDir);
            log.appendLine(`Sync complete: ${successCount} synced, ${failedCount} failed.`);
            const choice = await vscode.window.showWarningMessage(
                `Synced ${successCount} files. ${failedCount} files failed to sync.`, showLog);
            if (choice === showLog) { log.show(); }
        } else {
            log.appendLine(`Sync failed: all ${failedCount} files failed.`);
            const choice = await vscode.window.showErrorMessage(
                `Sync failed: all ${failedCount} files failed to sync.`, showLog);
            if (choice === showLog) { log.show(); }
        }
    } finally {
        isSyncing = false;
    }
}

async function registerDiscoveryPaths(promptsDir: vscode.Uri): Promise<void> {
    const pathKey = promptsDir.fsPath;

    for (const mapping of DIR_MAPPINGS) {
        const settingSection = mapping.setting.substring(0, mapping.setting.indexOf('.'));
        const settingName = mapping.setting.substring(mapping.setting.indexOf('.') + 1);
        const config = vscode.workspace.getConfiguration(settingSection);
        const current = config.get<Record<string, boolean>>(settingName) ?? {};

        if (current[pathKey] === true) {
            continue;
        }

        const updated = { ...current, [pathKey]: true };
        await config.update(settingName, updated, vscode.ConfigurationTarget.Global);
    }
}
