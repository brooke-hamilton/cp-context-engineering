import * as https from 'https';

export interface GitHubFileEntry {
    name: string;
    path: string;
    type: 'file' | 'dir';
    size: number;
    download_url: string | null;
}

function httpsGet(url: string, headers: Record<string, string>): Promise<{ statusCode: number; body: string }> {
    return new Promise((resolve, reject) => {
        const parsedUrl = new URL(url);
        const options: https.RequestOptions = {
            hostname: parsedUrl.hostname,
            path: parsedUrl.pathname + parsedUrl.search,
            headers,
        };
        https.get(options, (res) => {
            if (res.statusCode === 301 || res.statusCode === 302) {
                const redirectUrl = res.headers.location;
                if (redirectUrl) {
                    res.resume();
                    httpsGet(redirectUrl, headers).then(resolve, reject);
                    return;
                }
            }
            let data = '';
            res.on('data', (chunk: Buffer) => { data += chunk.toString(); });
            res.on('end', () => {
                resolve({ statusCode: res.statusCode ?? 0, body: data });
            });
        }).on('error', (err) => {
            reject(new Error(`Unable to reach GitHub API. Check your network connection. (${err.message})`));
        });
    });
}

function httpsGetBinary(url: string, headers: Record<string, string>): Promise<{ statusCode: number; body: Uint8Array }> {
    return new Promise((resolve, reject) => {
        const parsedUrl = new URL(url);
        const options: https.RequestOptions = {
            hostname: parsedUrl.hostname,
            path: parsedUrl.pathname + parsedUrl.search,
            headers,
        };
        https.get(options, (res) => {
            if (res.statusCode === 301 || res.statusCode === 302) {
                const redirectUrl = res.headers.location;
                if (redirectUrl) {
                    res.resume();
                    httpsGetBinary(redirectUrl, headers).then(resolve, reject);
                    return;
                }
            }
            const chunks: Buffer[] = [];
            res.on('data', (chunk: Buffer) => { chunks.push(chunk); });
            res.on('end', () => {
                resolve({ statusCode: res.statusCode ?? 0, body: new Uint8Array(Buffer.concat(chunks)) });
            });
        }).on('error', (err) => {
            reject(new Error(`Unable to reach GitHub API. Check your network connection. (${err.message})`));
        });
    });
}

const API_HEADERS: Record<string, string> = {
    'User-Agent': 'copilot-tools-sync-vscode',
    'Accept': 'application/vnd.github.v3+json',
};

export async function listDirectoryFiles(owner: string, repo: string, path: string): Promise<GitHubFileEntry[]> {
    const url = `https://api.github.com/repos/${encodeURIComponent(owner)}/${encodeURIComponent(repo)}/contents/${path}`;
    const response = await httpsGet(url, API_HEADERS);

    if (response.statusCode === 404) {
        return [];
    }
    if (response.statusCode === 403) {
        throw new Error('GitHub API rate limit exceeded. Try again later.');
    }
    if (response.statusCode >= 500) {
        throw new Error(`GitHub API error: HTTP ${response.statusCode}`);
    }
    if (response.statusCode !== 200) {
        throw new Error(`GitHub API error: HTTP ${response.statusCode}`);
    }

    const parsed: unknown = JSON.parse(response.body);
    if (!Array.isArray(parsed)) {
        return [];
    }
    return parsed as GitHubFileEntry[];
}

export async function downloadFileContent(url: string): Promise<Uint8Array> {
    const response = await httpsGetBinary(url, {
        'User-Agent': 'copilot-tools-sync-vscode',
    });

    if (response.statusCode !== 200) {
        throw new Error(`Failed to download file: HTTP ${response.statusCode}`);
    }
    return response.body;
}
