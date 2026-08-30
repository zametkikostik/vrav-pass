import {
  getSessionItems,
  clearSession,
  findForUrl,
  unlockWithPassword,
  storeLockedBlob,
  lockItemsWithPassword,
} from './lib/vault.js';
import { hostFindForUrl, hostStatus, pingHost } from './lib/native_host.js';

chrome.runtime.onInstalled.addListener(() => {
  console.log('Vrav Pass extension installed');
});

chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  handleMessage(message, sender).then(sendResponse).catch((e) => {
    sendResponse({ ok: false, error: e.message || String(e) });
  });
  return true;
});

async function handleMessage(message) {
  switch (message?.type) {
    case 'ping':
      return { ok: true, version: '0.3.0' };

    case 'pingHost': {
      try {
        const r = await pingHost();
        return { ok: true, host: r };
      } catch (e) {
        return { ok: false, error: e.message || String(e) };
      }
    }

    case 'hostStatus': {
      try {
        const r = await hostStatus();
        return { ok: true, host: r };
      } catch (e) {
        return { ok: false, error: e.message || String(e) };
      }
    }

    case 'getStatus': {
      const items = await getSessionItems();
      let host = null;
      try {
        host = await hostStatus();
      } catch (_) {
        /* host optional */
      }
      return {
        ok: true,
        unlocked: !!items,
        count: items ? items.length : 0,
        hostConnected: !!(host && host.ok),
        host,
      };
    }

    case 'unlock': {
      const items = await unlockWithPassword(message.password);
      return { ok: true, count: items.length };
    }

    case 'lock': {
      await clearSession();
      return { ok: true };
    }

    case 'getItems': {
      const items = await getSessionItems();
      if (!items) return { ok: false, error: 'locked' };
      return { ok: true, items };
    }

    case 'findForTab': {
      // Prefer desktop host when available; fall back to extension cache
      try {
        const host = await hostFindForUrl(message.url);
        if (host?.ok && Array.isArray(host.matches) && host.matches.length) {
          return { ok: true, matches: host.matches, source: 'host' };
        }
      } catch (_) {
        /* fall through */
      }
      const items = await getSessionItems();
      if (!items) return { ok: false, error: 'locked' };
      const matches = findForUrl(items, message.url);
      return { ok: true, matches, source: 'extension' };
    }

    case 'importBlob': {
      const bin = Uint8Array.from(atob(message.blobB64), (c) => c.charCodeAt(0));
      await storeLockedBlob(bin);
      return { ok: true };
    }

    case 'importItemsAndLock': {
      await lockItemsWithPassword(message.password, message.items);
      return { ok: true, count: message.items.length };
    }

    default:
      return { ok: false, error: 'unknown message' };
  }
}
