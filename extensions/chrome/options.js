const jsonEl = document.getElementById('json');
const pwdEl = document.getElementById('pwd');
const btn = document.getElementById('btn-import');
const msg = document.getElementById('msg');
const btnHost = document.getElementById('btn-ping-host');
const hostResult = document.getElementById('host-result');

btn.addEventListener('click', async () => {
  msg.textContent = '';
  try {
    const items = JSON.parse(jsonEl.value);
    if (!Array.isArray(items)) throw new Error('JSON must be an array');
    const password = pwdEl.value;
    if (!password || password.length < 8) throw new Error('Password min 8 chars');

    const normalized = items.map((it) => ({
      type: it.type || 'password',
      id: it.id,
      title: it.title || '',
      username: it.username || null,
      password: it.password || null,
      url: it.url || null,
      notes: it.notes || null,
      content: it.content || null,
      description: it.description || null,
    }));

    const res = await chrome.runtime.sendMessage({
      type: 'importItemsAndLock',
      password,
      items: normalized,
    });
    if (!res.ok) throw new Error(res.error || 'Import failed');
    msg.textContent = `Imported ${res.count} items. Open popup and unlock.`;
    pwdEl.value = '';
  } catch (e) {
    msg.textContent = e.message || String(e);
  }
});

btnHost.addEventListener('click', async () => {
  hostResult.textContent = 'Pinging com.vravpass.host…';
  try {
    const res = await chrome.runtime.sendMessage({ type: 'pingHost' });
    hostResult.textContent = JSON.stringify(res, null, 2);
  } catch (e) {
    hostResult.textContent = e.message || String(e);
  }
});
