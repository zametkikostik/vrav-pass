/** Chrome Native Messaging client for com.vravpass.host */

export const HOST_NAME = 'com.vravpass.host';

/**
 * Send a message to the native host.
 * @returns {Promise<object>} host response
 */
export function sendNative(message) {
  return new Promise((resolve, reject) => {
    try {
      chrome.runtime.sendNativeMessage(HOST_NAME, message, (response) => {
        if (chrome.runtime.lastError) {
          reject(new Error(chrome.runtime.lastError.message));
          return;
        }
        resolve(response || { ok: false, error: 'empty response' });
      });
    } catch (e) {
      reject(e);
    }
  });
}

export async function pingHost() {
  return sendNative({ type: 'ping' });
}

export async function hostStatus() {
  return sendNative({ type: 'getStatus' });
}

export async function hostFindForUrl(url) {
  return sendNative({ type: 'findForUrl', url });
}
