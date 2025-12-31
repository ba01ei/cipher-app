#!/usr/bin/env node

const { execSync, spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const SCHEME = 'cipher';
const PROJ = 'cipher';
 
// --- Helpers ---
function run(command, cwd = process.cwd(), stdio = 'inherit') {
    console.log(`Running: ${command}`);
    try {
        return execSync(command, { cwd, encoding: 'utf8', stdio });
    } catch (e) {
        if (stdio === 'pipe') {
            return e.stdout ? e.stdout.toString() : ''; // Return stdout even on error if available
        }
        throw e;
    }
}

function getJSON(command) {
    const output = run(command, process.cwd(), 'pipe');
    return JSON.parse(output);
}

// --- Device Discovery ---
function getDevices() {
    const devices = [];

    // 1. Simulators
    try {
        console.log('Querying Simulators...');
        const simctlOutput = getJSON('xcrun simctl list devices --json');
        for (const runtime in simctlOutput.devices) {
            simctlOutput.devices[runtime].forEach(device => {
                // only include available and booted/shutdown simulators (not unavailable)
                if (device.isAvailable) {
                    devices.push({
                        name: device.name,
                        udid: device.udid,
                        type: 'simulator',
                        state: device.state, // Booted, Shutdown
                        runtime: runtime
                    });
                }
            });
        }
    } catch (e) {
        console.warn('Failed to list simulators:', e.message);
    }

    // 2. Real Devices
    try {
        console.log('Querying Real Devices...');
        // devicectl writes to a file
        const tmpFile = `/tmp/devicectl_devices_${Date.now()}.json`;
        run(`xcrun devicectl list devices --json-output ${tmpFile}`, process.cwd(), 'pipe');
        if (fs.existsSync(tmpFile)) {
            const content = fs.readFileSync(tmpFile, 'utf8');
            fs.unlinkSync(tmpFile);
            const devicectlOutput = JSON.parse(content);
            // Verify structure: devicectlOutput.result.devices
            if (devicectlOutput.result && devicectlOutput.result.devices) {
                devicectlOutput.result.devices.forEach(device => {
                    devices.push({
                        name: device.deviceProperties.name,
                        udid: device.hardwareProperties.udid,
                        type: 'real',
                        connection: device.connectionProperties.transportType
                    });
                });
            }
        }
    } catch (e) {
        // Expected if no real device connected or devicectl missing
        console.warn('Note: Failed to query real devices (xcrun devicectl). ignoring.');
    }

    return devices;
}


// --- Main ---
async function main() {
    const args = process.argv.slice(2);
    const flags = {
        console: args.includes('--console'),
        skipBuild: args.includes('--skipBuild')
    };
    // Filter out flags to get the device name
    const targetName = args.filter(arg => !arg.startsWith('--')).join(' ');

    if (!targetName) {
        console.error('Usage: ./run.js <DeviceName> [--console] [--skipBuild]');
        console.log('\nAvailable Devices:');
        const devices = getDevices();
        devices.forEach(d => console.log(` - ${d.name} (${d.type}) [${d.udid}]`));
        process.exit(1);
    }

    console.log(`Looking for device: "${targetName}"...`);
    const allDevices = getDevices();
    const matches = allDevices.filter(d => d.name === targetName);

    if (matches.length === 0) {
        console.error(`Error: Device "${targetName}" not found.`);
        console.log('\nAvailable Devices:');
        allDevices.forEach(d => console.log(` - ${d.name} (${d.type})`));
        process.exit(1);
    }

    // If multiple matches, prefer Booted simulator or connected real device?
    // For now, just pick the first one, but maybe prefer exact match if fuzzy?
    // The previous filter was exact match.
    const device = matches[0];
    console.log(`Found device: ${device.name} (${device.udid}) - ${device.type}`);


    // --- Build ---
    // We assume the app is already there if skipping build, but we still need the bundleID and path.
    // So we must run xcodebuild -showBuildSettings regardless.

    let destinationSpecifier = '';
    let sdk = '';
    if (device.type === 'simulator') {
        destinationSpecifier = `platform=iOS Simulator,id=${device.udid}`;
        sdk = 'iphonesimulator';
    } else {
        destinationSpecifier = `platform=iOS,id=${device.udid}`;
        sdk = 'iphoneos';
    }

    // 1. Get Build Settings to find paths
    // We run xcodebuild -showBuildSettings with the same destination to ensure we get the right paths (like effective platform name)
    const settingsCmd = `xcodebuild -project ${PROJ}.xcodeproj -scheme ${SCHEME} -destination "${destinationSpecifier}" -showBuildSettings`;

    // Only log if we are actually building or if verbose (not implemented)
    // But getting settings is fast.
    if (!flags.skipBuild) {
        console.log('\n--- Building ---');
        console.log('getting build settings...');
    } else {
        console.log('getting build settings (for paths)...');
    }

    const settingsOutput = run(settingsCmd, process.cwd(), 'pipe');

    function getSetting(key) {
        const regex = new RegExp(`^\\s*${key}\\s*=\\s*(.*)$`, 'm');
        const match = settingsOutput.match(regex);
        return match ? match[1].trim() : null;
    }

    const TARGET_BUILD_DIR = getSetting('TARGET_BUILD_DIR');
    const FULL_PRODUCT_NAME = getSetting('FULL_PRODUCT_NAME');
    const PRODUCT_BUNDLE_IDENTIFIER = getSetting('PRODUCT_BUNDLE_IDENTIFIER');

    if (!TARGET_BUILD_DIR || !FULL_PRODUCT_NAME || !PRODUCT_BUNDLE_IDENTIFIER) {
        console.error('Failed to extract build settings.');
        process.exit(1);
    }

    const appPath = path.join(TARGET_BUILD_DIR, FULL_PRODUCT_NAME);

    if (!flags.skipBuild) {
        console.log(`Target App Path: ${appPath}`);
        console.log(`Bundle ID: ${PRODUCT_BUNDLE_IDENTIFIER}`);

        // 2. Run Build
        // Using -quiet to reduce noise, remove it if you want full logs
        run(`xcodebuild -project ${PROJ}.xcodeproj -scheme ${SCHEME} -destination "${destinationSpecifier}" build`);

        console.log('\n--- Install & Launch ---');
    } else {
        console.log('\n--- Launching (Skipping Build & Install) ---');
        // If we skip build, we usually skip install too? 
        // User asked "skips xcodebuild and install, and only does the launch step"
        // So yes, skip install.
    }


    if (device.type === 'simulator') {
        if (device.state !== 'Booted') {
            console.log('Booting simulator...');
            run(`xcrun simctl boot ${device.udid}`);
            // Wait a bit for boot? simctl usually handles it or returns quickly.
        }

        if (!flags.skipBuild) {
            console.log('Installing app...');
            run(`xcrun simctl install ${device.udid} "${appPath}"`);
        }

        console.log('Launching app...');
        let launchCmd = `xcrun simctl launch`;
        if (flags.console) {
            launchCmd += ' --console';
        }
        launchCmd += ` ${device.udid} ${PRODUCT_BUNDLE_IDENTIFIER}`;

        // If console is requested, we need to attach stdio so the user sees it interactively
        // run() uses inherit by default, so it should be fine.
        run(launchCmd);

    } else {
        // Real Device (devicectl)

        if (!flags.skipBuild) {
            console.log('Installing app to device...');
            run(`xcrun devicectl device install app --device ${device.udid} "${appPath}"`);
        }

        console.log('Launching app on device...');
        // For launch, we usually need the bundleID, but devicectl launch might work with URL or something?
        // Checking devicectl help: `xcrun devicectl device process launch ... <bundleID>`
        let launchCmd = `xcrun devicectl device process launch`;
        if (flags.console) {
            launchCmd += ' --console';
        }
        launchCmd += ` --device ${device.udid} ${PRODUCT_BUNDLE_IDENTIFIER}`;

        run(launchCmd);
    }

    console.log('\n✅ Done!');
}

main().catch(err => {
    console.error('Fatal Error:', err);
    process.exit(1);
});
