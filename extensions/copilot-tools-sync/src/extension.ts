import * as vscode from 'vscode';
import { syncCopilotTools } from './sync';

const outputChannel = vscode.window.createOutputChannel('Copilot Tools Sync');

export function activate(context: vscode.ExtensionContext): void {
    const disposable = vscode.commands.registerCommand(
        'copilotToolsSync.sync',
        () => syncCopilotTools(outputChannel, context)
    );
    context.subscriptions.push(disposable, outputChannel);
}

export function deactivate(): void {
    // No cleanup required
}
