import axios from 'axios';
import { readdir, readFile } from 'node:fs/promises';
import { env } from 'node:process';

async function getNightlyRelease() {
    const config = {
        method: 'get',
        headers: {
            'X-GitHub-Api-Version': '2022-11-28',
            Authorization: `token ${env.token}`
        },
        url: 'https://api.github.com/repos/sabrogden/Ditto/releases'
    };

    const { data } = await axios(config);

    return data.find((release) => release.tag_name === 'nightly');
}

async function deleteOldAssets(nightlyRelease) {
    for (const asset of nightlyRelease.assets) {
        const config = {
            method: 'DELETE',
            headers: {
                'X-GitHub-Api-Version': '2022-11-28',
                Authorization: `token ${env.token}`
            },
            url: `https://api.github.com/repos/sabrogden/Ditto/releases/assets/${asset.id}`
        };

        console.log(`Deleting file ${asset.name}, id: ${asset.id}`);
        await axios(config);
    }
}

async function uploadFiles(nightlyRelease) {
    const files = await readdir(env.uploadPath);

    for (const file of files) {
        if (!file.startsWith('Ditto')) {
            continue;
        }

        const fullPath = `${env.uploadPath}${file}`;
        const fileBytes = await readFile(fullPath);

        const config = {
            method: 'POST',
            headers: {
                'X-GitHub-Api-Version': '2022-11-28',
                Authorization: `token ${env.token}`,
                'Content-Type': 'application/octet-stream',
                'Content-Length': fileBytes.length
            },
            url: `https://uploads.github.com/repos/sabrogden/Ditto/releases/${nightlyRelease.id}/assets?name=${file}`,
            data: fileBytes
        };

        console.log(`Uploading file ${fullPath}`);
        await axios(config);
    }
}

async function updateReleaseNotes(nightlyRelease) {
    const generatedNotesConfig = {
        method: 'POST',
        headers: {
            'X-GitHub-Api-Version': '2022-11-28',
            Authorization: `token ${env.token}`
        },
        url: 'https://api.github.com/repos/sabrogden/Ditto/releases/generate-notes',
        data: {
            tag_name: env.tag,
            previous_tag_name: env.previous_tag
        }
    };

    console.log('Generating release notes');
    const { data } = await axios(generatedNotesConfig);
    const releaseNotes = data.body;

    const updateReleaseConfig = {
        method: 'PATCH',
        headers: {
            'X-GitHub-Api-Version': '2022-11-28',
            Authorization: `token ${env.token}`
        },
        url: `https://api.github.com/repos/sabrogden/Ditto/releases/${nightlyRelease.id}`,
        data: {
            body: releaseNotes
        }
    };

    console.log(`Uploading release notes: ${releaseNotes}`);
    await axios(updateReleaseConfig);
}

async function main() {
    const nightlyRelease = await getNightlyRelease();

    if (!nightlyRelease) {
        throw new Error('No nightly release found');
    }

    await deleteOldAssets(nightlyRelease);
    await uploadFiles(nightlyRelease);
    await updateReleaseNotes(nightlyRelease);
}

await main();
