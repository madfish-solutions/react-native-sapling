#!/usr/bin/env node

/**
 * Downloads the SaplingFFI.xcframework from the madfish-sapling GitHub repo
 * and patches the C headers to use angle-bracket system includes.
 *
 * Runs as an npm postinstall hook. Skips on non-macOS platforms since the
 * xcframework is only needed for iOS builds.
 */

const { execSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const SAPLING_VERSION = '0.0.11-beta03';
const REPO_URL = 'https://github.com/madfish-solutions/madfish-sapling.git';
const ROOT = path.resolve(__dirname, '..');
const XCF_DIR = path.join(ROOT, 'SaplingFFI.xcframework');

if (process.platform !== 'darwin') {
  console.log('[react-native-sapling] Skipping SaplingFFI download (not macOS).');
  process.exit(0);
}

if (fs.existsSync(path.join(XCF_DIR, 'Info.plist'))) {
  console.log('[react-native-sapling] SaplingFFI.xcframework already present, skipping download.');
  process.exit(0);
}

const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'sapling-xcf-'));

try {
  console.log(`[react-native-sapling] Downloading SaplingFFI.xcframework (${SAPLING_VERSION})...`);

  execSync(
    `git clone --depth 1 --filter=blob:none --sparse --branch "${SAPLING_VERSION}" "${REPO_URL}" repo`,
    { cwd: tmpDir, stdio: 'pipe' }
  );
  execSync(
    'git sparse-checkout set packages/sapling-ios/SaplingFFI.xcframework',
    { cwd: path.join(tmpDir, 'repo'), stdio: 'pipe' }
  );
  execSync(
    `cp -R "${path.join(tmpDir, 'repo', 'packages', 'sapling-ios', 'SaplingFFI.xcframework')}" "${ROOT}/"`,
    { stdio: 'pipe' }
  );

  // Patch all headers inside the xcframework in-place.
  // The upstream header uses #include "stdlib.h" (quoted), which causes the
  // compiler to search pod HEADER_SEARCH_PATHS first and pick up Folly's
  // Stdlib.h (C++) instead of the system C <stdlib.h>. Switching to angle
  // brackets fixes this.
  const archDirs = fs.readdirSync(XCF_DIR).filter(d => d.startsWith('ios-'));
  for (const arch of archDirs) {
    const headerPath = path.join(XCF_DIR, arch, 'Headers', 'madfish_sapling.h');
    if (fs.existsSync(headerPath)) {
      let header = fs.readFileSync(headerPath, 'utf8');
      header = header
        .replace(/#include\s+"stdlib\.h"/g,  '#include <stdlib.h>')
        .replace(/#include\s+"stddef\.h"/g,  '#include <stddef.h>')
        .replace(/#include\s+"stdbool\.h"/g, '#include <stdbool.h>');
      fs.writeFileSync(headerPath, header);
    }
  }

  console.log('[react-native-sapling] SaplingFFI.xcframework downloaded and patched.');
} catch (err) {
  console.error('[react-native-sapling] Failed to download SaplingFFI.');
  console.error(err.message);
  console.error(
    '[react-native-sapling] You can download it manually from:\n' +
    `  ${REPO_URL.replace('.git', '')}/tree/${SAPLING_VERSION}/packages/sapling-ios/SaplingFFI.xcframework\n` +
    `  and place it at: ${XCF_DIR}`
  );
  process.exit(1);
} finally {
  try { execSync(`rm -rf "${tmpDir}"`, { stdio: 'ignore' }); } catch (_) {}
}
