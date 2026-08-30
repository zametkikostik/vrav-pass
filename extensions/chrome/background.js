// Vrav Pass background service worker (MV3)
// Future: Native Messaging host communication, autofill coordination, sync status

chrome.runtime.onInstalled.addListener(() => {
  console.log('Vrav Pass extension installed');
});

// Placeholder for messages from content scripts / popup
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message?.type === 'ping') {
    sendResponse({ ok: true, version: '0.1.0' });
  }
  return true;
});
