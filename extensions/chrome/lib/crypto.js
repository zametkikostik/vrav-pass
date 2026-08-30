/**
 * Crypto helpers compatible with mobile Vrav Pass vault format.
 *
 * Vault file layout (vault.v1.enc):
 *   nonce (12 bytes) || ciphertext || tag (16 bytes)  — AES-256-GCM
 * AAD: utf8("vrav-vault-v1")
 *
 * Master key: Argon2id(password, salt, m=65536, t=3, p=4) → 32 bytes
 * DEK: HKDF-SHA512(master, info="vrav-dek-v1")
 *
 * Note: Full Argon2id in pure JS is heavy. We use Web Crypto AES-GCM
 * and document that unlock requires salt + derived key material
 * stored after first successful mobile export handshake, OR
 * user pastes/import already-decrypted item list for the session.
 *
 * For production parity we integrate hash-wasm Argon2 when available.
 */

const AAD = new TextEncoder().encode('vrav-vault-v1');
const NONCE_LEN = 12;
const TAG_LEN = 16;

export function b64ToBytes(b64) {
  const bin = atob(b64);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

export function bytesToB64(bytes) {
  let s = '';
  for (let i = 0; i < bytes.length; i++) s += String.fromCharCode(bytes[i]);
  return btoa(s);
}

export async function importAesKey(raw32) {
  return crypto.subtle.importKey('raw', raw32, { name: 'AES-GCM' }, false, [
    'encrypt',
    'decrypt',
  ]);
}

/** Decrypt vault.v1.enc blob with DEK (32 bytes). */
export async function decryptVaultBlob(dekRaw, cipherBytes) {
  if (cipherBytes.length < NONCE_LEN + TAG_LEN) {
    throw new Error('Ciphertext too short');
  }
  const nonce = cipherBytes.slice(0, NONCE_LEN);
  const rest = cipherBytes.slice(NONCE_LEN);
  // Web Crypto expects ciphertext||tag together
  const key = await importAesKey(dekRaw);
  const plain = await crypto.subtle.decrypt(
    { name: 'AES-GCM', iv: nonce, additionalData: AAD, tagLength: 128 },
    key,
    rest
  );
  return new TextDecoder().decode(plain);
}

/** Encrypt JSON string to vault blob format. */
export async function encryptVaultBlob(dekRaw, jsonString) {
  const nonce = crypto.getRandomValues(new Uint8Array(NONCE_LEN));
  const key = await importAesKey(dekRaw);
  const plain = new TextEncoder().encode(jsonString);
  const cipherWithTag = new Uint8Array(
    await crypto.subtle.encrypt(
      { name: 'AES-GCM', iv: nonce, additionalData: AAD, tagLength: 128 },
      key,
      plain
    )
  );
  const out = new Uint8Array(NONCE_LEN + cipherWithTag.length);
  out.set(nonce, 0);
  out.set(cipherWithTag, NONCE_LEN);
  return out;
}

/**
 * HKDF-SHA512 extract+expand (simplified for our fixed info strings).
 * Uses Web Crypto HKDF if available (Chrome supports HKDF with SHA-256/384/512).
 */
export async function hkdfSha512(masterRaw, infoStr, length = 32) {
  const baseKey = await crypto.subtle.importKey(
    'raw',
    masterRaw,
    'HKDF',
    false,
    ['deriveBits']
  );
  const bits = await crypto.subtle.deriveBits(
    {
      name: 'HKDF',
      hash: 'SHA-512',
      salt: new Uint8Array(0),
      info: new TextEncoder().encode(infoStr),
    },
    baseKey,
    length * 8
  );
  return new Uint8Array(bits);
}

/**
 * Session-only unlock: user provides DEK as base64 (exported from mobile once)
 * OR we store salt in extension and run Argon2 via optional WASM later.
 * For v0.2 we support:
 *  1) Import .enc + DEK base64 (advanced)
 *  2) Import plaintext JSON items for session (dev)
 *  3) Store items encrypted with a password-derived key via PBKDF2 fallback
 *     (documented as temporary until Argon2 WASM is bundled)
 */
export async function deriveKeyPbkdf2(password, salt, iterations = 310000) {
  const enc = new TextEncoder();
  const keyMaterial = await crypto.subtle.importKey(
    'raw',
    enc.encode(password),
    'PBKDF2',
    false,
    ['deriveBits']
  );
  const bits = await crypto.subtle.deriveBits(
    {
      name: 'PBKDF2',
      salt,
      iterations,
      hash: 'SHA-256',
    },
    keyMaterial,
    256
  );
  return new Uint8Array(bits);
}
