import { WebPlugin } from '@capacitor/core';

import type { MenuBarPlugin, SetMenuOptions } from './definitions';

/**
 * No-op fallback for the web (and for any platform without a menu bar).
 *
 * Resolves instead of throwing `Unimplemented` so shared startup code can call `setMenu`
 * on every platform. `isSupported()` returns `false` here.
 */
export class MenuBarWeb extends WebPlugin implements MenuBarPlugin {
  async isSupported(): Promise<{ supported: boolean }> {
    return { supported: false };
  }

  async setMenu(_options: SetMenuOptions): Promise<void> {
    return;
  }

  async clearMenu(): Promise<void> {
    return;
  }
}
