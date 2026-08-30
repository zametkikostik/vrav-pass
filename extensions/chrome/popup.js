document.getElementById('status').textContent = 'Vault locked (stub)';

document.getElementById('open-app').addEventListener('click', () => {
  // Future: communicate with native host or open options
  chrome.runtime.openOptionsPage();
});
