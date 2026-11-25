import { registerPlugin } from '@capacitor/core';

import type { MenuBarPlugin } from './definitions';

const MenuBar = registerPlugin<MenuBarPlugin>('MenuBar', {
  web: () => import('./web').then((m) => new m.MenuBarWeb()),
});

export * from './definitions';
export { MenuBar };
