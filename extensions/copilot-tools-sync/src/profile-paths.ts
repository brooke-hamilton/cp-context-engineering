import * as vscode from 'vscode';
import * as path from 'path';
import { execSync } from 'child_process';

// HACK: The VS Code extension API (vscode.env, ExtensionContext) does not expose
// the client-side user profile path. Properties like globalStorageUri, storageUri,
// and logUri all resolve to the extension host machine, which is the remote server
// in WSL/SSH scenarios, not the client. When running locally, we navigate up from
// globalStorageUri. When running in WSL, we shell out to cmd.exe to resolve
// %APPDATA%. Neither approach handles SSH remotes to Mac/Linux, where
// globalStorageUri points to the remote server, not the client.
// TODO: Find a proper VS Code API for the client-side user profile path
export function resolvePromptsPath(context: vscode.ExtensionContext): vscode.Uri {
    if (vscode.env.remoteName === 'wsl') {
        return resolveWindowsPromptsPath();
    }

    // Local desktop or non-WSL remote: navigate up from globalStorageUri
    // globalStorageUri is <userDataDir>/User/globalStorage/<publisher.extension>
    const userDir = path.resolve(context.globalStorageUri.fsPath, '..', '..');
    return vscode.Uri.file(path.join(userDir, 'prompts'));
}

function resolveWindowsPromptsPath(): vscode.Uri {
    const appData = execSync('cmd.exe /c echo %APPDATA%', { encoding: 'utf8' }).replace(/[\r\n]+/g, '');
    const wslAppData = execSync(`wslpath -u "${appData}"`, { encoding: 'utf8' }).trim();
    const codeDirName = vscode.env.appName.includes('Insiders') ? 'Code - Insiders' : 'Code';
    return vscode.Uri.file(path.join(wslAppData, codeDirName, 'User', 'prompts'));
}
