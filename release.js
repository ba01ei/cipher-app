#!/usr/bin/env node

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const DEFAULT_SCHEME = 'cipher';
const DEFAULT_CONFIGURATION = 'Release';
const DEFAULT_PROJECT_NAME = 'cipher.xcodeproj';

function usage() {
  console.log(`Usage: ./release.js [ios|mac|both] [options]

Archives cipher for App Store distribution and uploads it to App Store Connect
using the Apple account/provisioning configured in Xcode.

The optional target is ios, mac, or both (default).

Options:
  --scheme <name>          Xcode scheme (default: ${DEFAULT_SCHEME})
  --configuration <name>   Build configuration (default: ${DEFAULT_CONFIGURATION})
  --team-id <id>           Apple Developer Team ID (default: value from project)
  --archive-path <path>    Output .xcarchive path
  --export-path <path>     xcodebuild export working/output directory
  --skip-archive           Reuse an existing archive-path
  --skip-upload            Create the archive only; do not upload
  --clean                  Clean before archiving
  --verbose                Show full xcodebuild output
  -h, --help               Show this help

Examples:
  ./release.js
  ./release.js ios
  ./release.js mac
  ./release.js --clean
  ./release.js --archive-path build/release/cipher.xcarchive --skip-upload
`);
}

function parseArgs(argv) {
  let target = 'both';
  if (argv[0] && !argv[0].startsWith('--')) {
    target = argv.shift().toLowerCase();
    if (!['ios', 'mac', 'both'].includes(target)) {
      throw new Error(`Unknown release target: ${target}. Use ios, mac, or both.`);
    }
  }

  const opts = {
    target,
    scheme: DEFAULT_SCHEME,
    configuration: DEFAULT_CONFIGURATION,
    clean: false,
    verbose: false,
    skipArchive: false,
    skipUpload: false,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    const nextValue = () => {
      const value = argv[i + 1];
      if (!value || value.startsWith('--')) {
        throw new Error(`Missing value for ${arg}`);
      }
      i += 1;
      return value;
    };

    switch (arg) {
      case '-h':
      case '--help':
        opts.help = true;
        break;
      case '--scheme':
        opts.scheme = nextValue();
        break;
      case '--configuration':
        opts.configuration = nextValue();
        break;
      case '--team-id':
        opts.teamId = nextValue();
        break;
      case '--archive-path':
        opts.archivePath = nextValue();
        break;
      case '--export-path':
        opts.exportPath = nextValue();
        break;
      case '--clean':
        opts.clean = true;
        break;
      case '--verbose':
        opts.verbose = true;
        break;
      case '--skip-archive':
        opts.skipArchive = true;
        break;
      case '--skip-upload':
        opts.skipUpload = true;
        break;
      default:
        throw new Error(`Unknown option: ${arg}`);
    }
  }

  return opts;
}

function shellQuote(value) {
  return `'${String(value).replace(/'/g, `'\\''`)}'`;
}

function run(command, options = {}) {
  const { cwd = process.cwd(), capture = false, verbose = true } = options;
  console.log(`\n$ ${command}`);
  return execSync(command, {
    cwd,
    encoding: 'utf8',
    stdio: capture ? ['ignore', 'pipe', 'pipe'] : (verbose ? 'inherit' : ['ignore', 'pipe', 'pipe']),
  });
}

function findProjectRoot(startDir) {
  let dir = startDir;
  while (dir !== path.dirname(dir)) {
    if (fs.existsSync(path.join(dir, DEFAULT_PROJECT_NAME))) return dir;
    dir = path.dirname(dir);
  }
  throw new Error(`Could not find ${DEFAULT_PROJECT_NAME} from ${startDir}`);
}

function getBuildSettings(projectRoot, projectPath, scheme, configuration, platform) {
  const output = run([
    'xcodebuild',
    '-project', shellQuote(projectPath),
    '-scheme', shellQuote(scheme),
    '-configuration', shellQuote(configuration),
    '-destination', shellQuote(`generic/platform=${platform}`),
    '-showBuildSettings',
  ].join(' '), { cwd: projectRoot, capture: true });

  const get = (key) => {
    const match = output.match(new RegExp(`^\\s*${key}\\s*=\\s*(.*)$`, 'm'));
    return match ? match[1].trim() : undefined;
  };

  return {
    teamId: get('DEVELOPMENT_TEAM'),
    bundleId: get('PRODUCT_BUNDLE_IDENTIFIER'),
    marketingVersion: get('MARKETING_VERSION'),
    buildNumber: get('CURRENT_PROJECT_VERSION'),
  };
}

function writeExportOptionsPlist(filePath, { teamId }) {
  const teamIdEntry = teamId ? `\n  <key>teamID</key>\n  <string>${teamId}</string>` : '';
  const plist = `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>destination</key>
  <string>upload</string>
  <key>method</key>
  <string>app-store-connect</string>
  <key>signingStyle</key>
  <string>automatic</string>${teamIdEntry}
  <key>uploadSymbols</key>
  <true/>
</dict>
</plist>
`;
  fs.writeFileSync(filePath, plist);
}

function main() {
  const opts = parseArgs(process.argv.slice(2));
  if (opts.help) { usage(); return; }

  const scriptDir = __dirname;
  const projectRoot = findProjectRoot(scriptDir);
  const projectPath = path.join(projectRoot, DEFAULT_PROJECT_NAME);
  const releaseRoot = path.join(projectRoot, 'build', 'release');
  const stamp = new Date().toISOString().replace(/[-:]/g, '').replace(/\.\d{3}Z$/, 'Z');
  const targets = opts.target === 'both' ? ['ios', 'mac'] : [opts.target];

  fs.mkdirSync(releaseRoot, { recursive: true });

  for (const target of targets) {
    const platform = target === 'mac' ? 'macOS' : 'iOS';
    const buildSettings = getBuildSettings(projectRoot, projectPath, opts.scheme, opts.configuration, platform);
    const teamId = opts.teamId || buildSettings.teamId;
    const archivePath = path.resolve(projectRoot, opts.archivePath || path.join(releaseRoot, `${opts.scheme}-${target}-${stamp}.xcarchive`));
    const exportPath = path.resolve(projectRoot, opts.exportPath || path.join(releaseRoot, `export-${target}-${stamp}`));
    const exportOptionsPath = path.join(releaseRoot, `ExportOptions-${target}-${stamp}.plist`);

    fs.mkdirSync(path.dirname(archivePath), { recursive: true });
    fs.mkdirSync(exportPath, { recursive: true });
    writeExportOptionsPlist(exportOptionsPath, { teamId });

    console.log(`\nRelease target: ${target}`);
    console.log(`  Project:       ${projectPath}`);
    console.log(`  Scheme:        ${opts.scheme}`);
    console.log(`  Configuration: ${opts.configuration}`);
    console.log(`  Bundle ID:     ${buildSettings.bundleId || '(unknown)'}`);
    console.log(`  Version:       ${(buildSettings.marketingVersion || '?')} (${buildSettings.buildNumber || '?'})`);
    console.log(`  Team ID:       ${teamId || '(from Xcode account)'}`);
    console.log(`  Archive:       ${archivePath}`);
    console.log(`  Export path:   ${exportPath}`);

    if (!opts.skipArchive) {
      const archiveCommand = [
        'xcodebuild', opts.clean ? 'clean' : '', 'archive',
        '-project', shellQuote(projectPath), '-scheme', shellQuote(opts.scheme),
        '-configuration', shellQuote(opts.configuration), '-destination', shellQuote(`generic/platform=${platform}`),
        '-archivePath', shellQuote(archivePath), '-allowProvisioningUpdates',
      ].filter(Boolean).join(' ');
      run(archiveCommand, { cwd: projectRoot, verbose: opts.verbose });
    }

    if (!fs.existsSync(archivePath)) throw new Error(`Archive was not found at ${archivePath}`);
    if (opts.skipUpload) continue;

    console.log(`\nUploading ${target} to App Store Connect with xcodebuild -exportArchive.`);
    const uploadCommand = [
      'xcodebuild', '-exportArchive', '-archivePath', shellQuote(archivePath),
      '-exportOptionsPlist', shellQuote(exportOptionsPath), '-exportPath', shellQuote(exportPath),
      '-allowProvisioningUpdates',
    ].join(' ');
    run(uploadCommand, { cwd: projectRoot, verbose: opts.verbose });
    console.log(`\n✅ ${target} archive uploaded to App Store Connect.`);
  }

  if (opts.skipUpload) console.log('\n✅ Archive(s) created. Upload skipped.');
}

try {
  main();
} catch (error) {
  console.error(`\n❌ Release failed: ${error.message}`);
  console.error('\nMake sure you are signed in to Xcode and have App Manager/Admin access for this app.');
  process.exit(1);
}
