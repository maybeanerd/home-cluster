#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const usage = `
Usage: node cleanup-one-pace.js [-n|--dry-run] <base-path>

Renames One Pace episode files inside season folders named like "S01 - ...".
Each episode will be renamed to the form: SXXEXX [map] Title.ext
The mapping bracket [NNN-NNN] is ONLY included if it exists in the original filename.
Also removes any .nfo files found directly inside each season folder.

Options:
  -n, --dry-run   Show actions without making changes
  -h, --help      Show this help
`;

// Parse command line arguments
const args = process.argv.slice(2);
let dryRun = false;
let basePath = null;

for (let i = 0; i < args.length; i++) {
  const arg = args[i];
  if (arg === '-n' || arg === '--dry-run') {
    dryRun = true;
  } else if (arg === '-h' || arg === '--help') {
    console.log(usage);
    process.exit(0);
  } else if (!basePath) {
    basePath = arg;
  }
}

if (!basePath) {
  console.error('Error: base path required');
  console.log(usage);
  process.exit(1);
}

// Ensure base path exists and is a directory
try {
  const stat = fs.statSync(basePath);
  if (!stat.isDirectory()) {
    throw new Error('Not a directory');
  }
} catch (err) {
  console.error(
    `Error: path does not exist or is not a directory: ${basePath}`
  );
  process.exit(1);
}

console.log(`Base path: ${basePath}`);
if (dryRun) {
  console.log('DRY RUN: enabled (no changes will be made)');
}

// Process a single season directory
async function processSeason(seasonDir) {
  const seasonName = path.basename(seasonDir);

  // Require season folders to start with SDD -
  const seasonMatch = seasonName.match(/^S(\d{2})\s*-/);
  if (!seasonMatch) {
    console.error(`Skipping non-season folder: ${seasonDir}`);
    return;
  }

  const seasonNum = seasonMatch[1];
  console.log(`Processing season ${seasonNum}: ${seasonName}`);

  // Get all files in the season directory (non-recursive)
  const files = await fs.promises.readdir(seasonDir);

  // Process .nfo files first
  const nfoFiles = files.filter((f) => f.toLowerCase().endsWith('.nfo'));
  for (const nfo of nfoFiles) {
    const nfoPath = path.join(seasonDir, nfo);
    if (dryRun) {
      console.log(`DRY: rm '${nfoPath}'`);
    } else {
      try {
        console.log(`Removing: ${nfoPath}`);
        await fs.promises.unlink(nfoPath);
      } catch (err) {
        if (err.code === 'ENOENT') {
          console.log(`Note: .nfo file already removed: ${nfoPath}`);
        } else {
          throw err;
        }
      }
    }
  }

  // Process media files
  for (const file of files) {
    const filePath = path.join(seasonDir, file);
    let stat;
    try {
      stat = await fs.promises.stat(filePath);
    } catch (err) {
      if (err.code === 'ENOENT') {
        console.log(`Skipping non-existent file: ${filePath}`);
        continue;
      }
      throw err;
    }

    // Skip directories and .nfo files
    if (!stat.isFile() || file.toLowerCase().endsWith('.nfo')) {
      continue;
    }

    const ext = path.extname(file);
    const nameNoExt = path.basename(file, ext);

    // Extract mapping bracket from original filename
    const mapMatch = nameNoExt.match(/\[\d+-\d+\]/);
    const mapFromFile = mapMatch ? mapMatch[0] : '';

    // Check if file already has correct SXXEXX pattern
    const existingEpisodePattern = nameNoExt.match(/S\d{2}E\d{2}/g);
    if (existingEpisodePattern && existingEpisodePattern.length === 1) {
      console.log(`Skipping already correctly named file: ${file}`);
      continue;
    }

    // If multiple SXXEXX patterns exist, use the last one's episode number
    let epNum;
    if (existingEpisodePattern && existingEpisodePattern.length > 1) {
      const lastPattern =
        existingEpisodePattern[existingEpisodePattern.length - 1];
      epNum = lastPattern.match(/E(\d{2})/)[1];
      console.log(
        `Found multiple episode patterns in ${file}, using ${epNum} from ${lastPattern}`
      );
    } else {
      // Extract episode number (looking for E## pattern first, then standalone numbers)
      const epMatch =
        nameNoExt.match(/E(\d{1,3})/i) ||
        nameNoExt.match(/(?<![A-Za-z0-9])(\d{1,3})(?![A-Za-z0-9])/g);

      if (!epMatch) {
        console.error(
          `Warning: couldn't determine episode number for '${file}' -> skipping`
        );
        continue;
      }

      // If we found multiple standalone numbers and no E## pattern, take the last one
      epNum = Array.isArray(epMatch) ? epMatch[epMatch.length - 1] : epMatch[1];
    }

    const ep2 = epNum.toString().padStart(2, '0');

    // Clean title: remove leading bracketed content, mapping bracket, standalone numbers, and SXXEXX patterns
    let titleClean = nameNoExt
      .replace(/^\s*(?:\[[^\]]*\]\s*)+/, '') // strip leading [..] groups
      .replace(/\[\d+-\d+\]/g, '') // remove mapping brackets
      .replace(/S\d{2}E\d{2}/g, '') // remove any SXXEXX patterns
      .replace(/(?<![A-Za-z0-9])\d{1,3}(?![A-Za-z0-9])/g, '') // remove standalone numbers
      .replace(/\s+/g, ' ') // normalize spaces
      .trim();

    if (!titleClean) {
      titleClean = nameNoExt;
    }

    const seasonPrefix = `S${seasonNum}E${ep2}`;
    const newBase = mapFromFile
      ? `${seasonPrefix} ${mapFromFile} ${titleClean}`
      : `${seasonPrefix} ${titleClean}`;

    // Build new filename and path
    let newName = `${newBase}${ext}`;
    let newPath = path.join(seasonDir, newName);

    // avoid name collisions
    let suffix = 1;
    try {
      while (fs.existsSync(newPath)) {
        newName = `${newBase} (${suffix})${ext}`;
        newPath = path.join(seasonDir, newName);
        suffix++;
      }
    } catch (err) {
      if (err.code === 'ENOENT') {
        // Path doesn't exist, which is fine - we can use it
      } else {
        throw err;
      }
    }

    if (dryRun) {
      console.log(`DRY: mv '${filePath}' -> '${newPath}'`);
    } else {
      console.log(`Renaming: '${filePath}' -> '${newPath}'`);
      await fs.promises.rename(filePath, newPath);
    }
  }
}

// Main: process all season folders
async function main() {
  try {
    const items = await fs.promises.readdir(basePath);

    for (const item of items) {
      const fullPath = path.join(basePath, item);
      const stat = await fs.promises.stat(fullPath);

      if (stat.isDirectory() && item.match(/^S\d{2}\s*-/)) {
        await processSeason(fullPath);
      }
    }

    console.log('Done.');
  } catch (err) {
    console.error('Error:', err.message);
    process.exit(1);
  }
}

main();
