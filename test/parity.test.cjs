/**
 * The TypeScript types and the Swift tables list the same names. If they drift, a name the
 * types accept is ignored on the device, so this test compares them.
 */
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');

const root = join(__dirname, '..');
const read = (relativePath) => readFileSync(join(root, relativePath), 'utf8');

const definitions = read('src/definitions.ts');
const swiftSources = join('ios', 'Sources', 'MenuBarPlugin');

function unionMembers(typeName) {
  const declaration = definitions.match(new RegExp(`export type ${typeName} =([^;]+);`));

  assert.ok(declaration, `${typeName} not found in definitions.ts`);

  return [...declaration[1].matchAll(/'([^']+)'/g)].map((match) => match[1]).sort();
}

function swiftMatches(source, pattern) {
  return [...source.matchAll(pattern)].map((match) => match[1]).sort();
}

function swiftDeclaration(relativePath, header) {
  const source = read(join(swiftSources, relativePath));
  const start = source.indexOf(header);

  assert.ok(start >= 0, `${header} not found in ${relativePath}`);

  return source.slice(start, source.indexOf('\n}', start));
}

test('every system menu name the types accept is known to Swift, and no other', () => {
  const table = swiftDeclaration(join('Placement', 'MenuBarSystemMenus.swift'), 'static let identifiers');
  const swiftNames = swiftMatches(table, /^\s*"(\w+)": \./gm);

  assert.deepEqual(swiftNames, unionMembers('MenuBarSystemMenu'));
});

test('every role the types accept is known to Swift, and no other', () => {
  const roleEnum = swiftDeclaration(join('Descriptor', 'MenuBarRoleItem.swift'), 'public enum MenuBarRole:');
  const swiftRoles = swiftMatches(roleEnum, /^\s*case (\w+)$/gm);

  assert.deepEqual(swiftRoles, unionMembers('MenuBarRole'));
});

/** The name `cap sync` gives the plugin: what it writes into the Podfile and `CapApp-SPM`. */
function capacitorNativeName(npmName) {
  const camelCased = npmName
    .replace(/\//g, '_')
    .replace(/-/g, '_')
    .replace(/@/g, '')
    .replace(/_\w/g, (match) => match[1].toUpperCase());

  return camelCased.charAt(0).toUpperCase() + camelCased.slice(1);
}

test('the native package names are the ones `cap sync` will ask for', () => {
  const expected = capacitorNativeName(JSON.parse(read('package.json')).name);
  const manifest = read('Package.swift');

  assert.match(manifest, new RegExp(`let package = Package\\(\\s*name: "${expected}"`), 'Package.swift package name');
  assert.match(manifest, new RegExp(`\\.library\\(\\s*name: "${expected}"`), 'Package.swift product name');
  assert.match(read(`${expected}.podspec`), new RegExp(`s\\.name = '${expected}'`), 'podspec name');
});
