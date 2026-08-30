import {
  getSessionItems,
  clearSession,
  findForUrl,
  unlockWithPassword,
  storeLockedBlob,
  lockItemsWithPassword,
} from './lib/vault.js';

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
      return { ok: true, version: '0.2.0' };

    case 'getStatus': {
      const items = await getSessionItems();
      return { ok: true, unlocked: !!items, count: items ? items.length : 0 };
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
      const items = await getSessionItems();
      if (!items) return { ok: false, error: 'locked' };
      const matches = findForUrl(items, message.url);
      return { ok: true, matches };
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
