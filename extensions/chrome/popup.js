const viewLocked = document.getElementById('view-locked');
const viewUnlocked = document.getElementById('view-unlocked');
const pwdInput = document.getElementById('master-password');
const unlockBtn = document.getElementById('btn-unlock');
const lockBtn = document.getElementById('btn-lock');
const unlockError = document.getElementById('unlock-error');
const itemsList = document.getElementById('items-list');
const matchesList = document.getElementById('matches-list');
const matchesLabel = document.getElementById('matches-label');
const searchInput = document.getElementById('search');

let allItems = [];

function send(msg) {
  return chrome.runtime.sendMessage(msg);
}

async function refreshStatus() {
  const st = await send({ type: 'getStatus' });
  if (st.unlocked) {
    await showUnlocked();
  } else {
    showLocked();
  }
}

function showLocked() {
  viewLocked.hidden = false;
  viewUnlocked.hidden = true;
  lockBtn.hidden = true;
}

async function showUnlocked() {
  viewLocked.hidden = true;
  viewUnlocked.hidden = false;
  lockBtn.hidden = false;

  const res = await send({ type: 'getItems' });
  allItems = res.items || [];
  renderItems(allItems);

  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  if (tab?.url) {
    const m = await send({ type: 'findForTab', url: tab.url });
    renderMatches(m.matches || []);
  }
}

function renderMatches(matches) {
  matchesList.innerHTML = '';
  if (!matches.length) {
    matchesLabel.hidden = true;
    return;
  }
  matchesLabel.hidden = false;
  for (const it of matches) {
    matchesList.appendChild(itemEl(it, true));
  }
}

function renderItems(items) {
  itemsList.innerHTML = '';
  const passwords = items.filter((i) => i.type === 'password' || !i.type);
  if (!passwords.length) {
    itemsList.innerHTML = '<li class="sub">No items</li>';
    return;
  }
  for (const it of passwords) {
    itemsList.appendChild(itemEl(it, false));
  }
}

function itemEl(it, highlight) {
  const li = document.createElement('li');
  li.innerHTML = `
    <div class="title">${escapeHtml(it.title || '')}</div>
    <div class="sub">${escapeHtml(it.username || it.url || '')}</div>
    <div class="actions">
      <button data-act="user">User</button>
      <button data-act="pass">Pass</button>
      <button data-act="fill">Fill</button>
    </div>
  `;
  li.querySelector('[data-act="user"]').onclick = (e) => {
    e.stopPropagation();
    if (it.username) navigator.clipboard.writeText(it.username);
  };
  li.querySelector('[data-act="pass"]').onclick = (e) => {
    e.stopPropagation();
    if (it.password) navigator.clipboard.writeText(it.password);
  };
  li.querySelector('[data-act="fill"]').onclick = async (e) => {
    e.stopPropagation();
    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
    if (tab?.id) {
      chrome.tabs.sendMessage(tab.id, {
        type: 'fill',
        username: it.username || '',
        password: it.password || '',
      });
    }
  };
  return li;
}

function escapeHtml(s) {
  return String(s)
    .replace(/&/g, '&')
    .replace(/</g, '<')
    .replace(/>/g, '>');
}

unlockBtn.addEventListener('click', async () => {
  unlockError.hidden = true;
  const password = pwdInput.value;
  if (!password) return;
  unlockBtn.disabled = true;
  try {
    const res = await send({ type: 'unlock', password });
    if (!res.ok) throw new Error(res.error || 'Unlock failed');
    pwdInput.value = '';
    await showUnlocked();
  } catch (e) {
    unlockError.textContent = e.message || String(e);
    unlockError.hidden = false;
  } finally {
    unlockBtn.disabled = false;
  }
});

pwdInput.addEventListener('keydown', (e) => {
  if (e.key === 'Enter') unlockBtn.click();
});

lockBtn.addEventListener('click', async () => {
  await send({ type: 'lock' });
  showLocked();
});

searchInput.addEventListener('input', () => {
  const q = searchInput.value.toLowerCase();
  const filtered = allItems.filter(
    (i) =>
      (i.title || '').toLowerCase().includes(q) ||
      (i.username || '').toLowerCase().includes(q) ||
      (i.url || '').toLowerCase().includes(q)
  );
  renderItems(filtered);
});

refreshStatus();
