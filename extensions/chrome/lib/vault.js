import {
  bytesToB64,
  b64ToBytes,
  decryptVaultBlob,
  encryptVaultBlob,
  deriveKeyPbkdf2,
} from './crypto.js';

const STORAGE_KEYS = {
  lockedBlob: 'vrav_locked_blob_b64',
  salt: 'vrav_ext_salt_b64',
  unlocked: 'vrav_session_items', // session only via chrome.storage.session if available
};

/** Save encrypted vault blob (from mobile export) for later unlock. */
export async function storeLockedBlob(bytes) {
  await chrome.storage.local.set({
    [STORAGE_KEYS.lockedBlob]: bytesToB64(bytes),
  });
}

export async function getLockedBlob() {
  const r = await chrome.storage.local.get(STORAGE_KEYS.lockedBlob);
  if (!r[STORAGE_KEYS.lockedBlob]) return null;
  return b64ToBytes(r[STORAGE_KEYS.lockedBlob]);
}

/**
 * Unlock path A: user provides DEK (base64) from mobile "export key" future feature,
 * and we decrypt the stored .enc blob.
 */
export async function unlockWithDek(dekB64) {
  const blob = await getLockedBlob();
  if (!blob) throw new Error('No vault file imported');
  const dek = b64ToBytes(dekB64);
  const json = await decryptVaultBlob(dek, blob);
  const items = JSON.parse(json);
  await setSessionItems(items);
  return items;
}

/**
 * Unlock path B (extension-local cache):
 * Items encrypted with PBKDF2-derived key from master password.
 * Used when user saves passwords from extension itself or after JSON import.
 */
export async function lockItemsWithPassword(password, items) {
  let saltB64 = (await chrome.storage.local.get(STORAGE_KEYS.salt))[STORAGE_KEYS.salt];
  let salt;
  if (!saltB64) {
    salt = crypto.getRandomValues(new Uint8Array(16));
    saltB64 = bytesToB64(salt);
    await chrome.storage.local.set({ [STORAGE_KEYS.salt]: saltB64 });
  } else {
    salt = b64ToBytes(saltB64);
  }
  const key = await deriveKeyPbkdf2(password, salt);
  const cipher = await encryptVaultBlob(key, JSON.stringify(items));
  await chrome.storage.local.set({
    [STORAGE_KEYS.lockedBlob]: bytesToB64(cipher),
  });
  await setSessionItems(items);
}

export async function unlockWithPassword(password) {
  const saltB64 = (await chrome.storage.local.get(STORAGE_KEYS.salt))[STORAGE_KEYS.salt];
  const blob = await getLockedBlob();
  if (!blob || !saltB64) throw new Error('No local vault');
  const key = await deriveKeyPbkdf2(password, b64ToBytes(saltB64));
  const json = await decryptVaultBlob(key, blob);
  const items = JSON.parse(json);
  await setSessionItems(items);
  return items;
}

export async function setSessionItems(items) {
  // Prefer session storage (cleared when browser closes)
  if (chrome.storage.session) {
    await chrome.storage.session.set({ items });
  } else {
    await chrome.storage.local.set({ vrav_session_items: items });
  }
}

export async function getSessionItems() {
  if (chrome.storage.session) {
    const r = await chrome.storage.session.get('items');
    return r.items || null;
  }
  const r = await chrome.storage.local.get('vrav_session_items');
  return r.vrav_session_items || null;
}

export async function clearSession() {
  if (chrome.storage.session) {
    await chrome.storage.session.remove('items');
  }
  await chrome.storage.local.remove('vrav_session_items');
}

export function findForUrl(items, pageUrl) {
  if (!items || !pageUrl) return [];
  let host;
  try {
    host = new URL(pageUrl).hostname.replace(/^www\./, '');
  } catch {
    return [];
  }
  return items.filter((it) => {
    if (it.type !== 'password' || !it.url) return false;
    try {
      const h = new URL(it.url).hostname.replace(/^www\./, '');
      return h === host || host.endsWith('.' + h) || h.endsWith('.' + host);
    } catch {
      return (it.url || '').includes(host);
    }
  });
}
