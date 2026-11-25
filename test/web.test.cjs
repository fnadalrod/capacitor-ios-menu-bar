/**
 * The public JavaScript API on a platform with no menu bar, exercised through the built
 * CommonJS bundle: the same file a consumer's bundler resolves.
 *
 * Every call must resolve: shared startup code calls `setMenu` on every platform.
 */
const { test } = require('node:test');
const assert = require('node:assert/strict');

const { MenuBar } = require('../dist/plugin.cjs.js');

const fileMenu = {
  menus: [
    {
      type: 'submenu',
      id: 'file',
      title: 'File',
      replaces: 'file',
      items: [
        { type: 'action', id: 'file.new', title: 'New', shortcut: 'CmdOrCtrl+N' },
        { type: 'separator' },
        { type: 'role', role: 'copy', title: 'Copy' },
      ],
    },
  ],
};

test('reports that there is no menu bar', async () => {
  assert.deepEqual(await MenuBar.isSupported(), { supported: false });
});

test('accepts a menu without doing anything', async () => {
  await assert.doesNotReject(MenuBar.setMenu(fileMenu));
});

test('clears the menu without doing anything', async () => {
  await assert.doesNotReject(MenuBar.clearMenu());
});

test('lets a listener be added and removed', async () => {
  const handle = await MenuBar.addListener('menuItemSelected', () => undefined);

  await assert.doesNotReject(handle.remove());
  await assert.doesNotReject(MenuBar.removeAllListeners());
});
