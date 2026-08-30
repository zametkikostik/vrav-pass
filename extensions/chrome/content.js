// Vrav Pass content script — form detection + autofill

chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  if (message?.type === 'fill') {
    fillForm(message.username, message.password);
    sendResponse({ ok: true });
  }
  return true;
});

function fillForm(username, password) {
  const userFields = findUserFields();
  const passFields = findPasswordFields();

  if (userFields.length && username) {
    setValue(userFields[0], username);
  }
  if (passFields.length && password) {
    setValue(passFields[0], password);
  }
}

function findPasswordFields() {
  return [...document.querySelectorAll('input[type="password"]')].filter(visible);
}

function findUserFields() {
  const selectors = [
    'input[type="email"]',
    'input[type="text"][name*="user" i]',
    'input[type="text"][name*="login" i]',
    'input[type="text"][name*="email" i]',
    'input[type="text"][id*="user" i]',
    'input[type="text"][id*="login" i]',
    'input[type="text"][autocomplete="username"]',
    'input[type="text"][autocomplete="email"]',
    'input[name="username"]',
    'input[name="email"]',
  ];
  const found = [];
  for (const sel of selectors) {
    document.querySelectorAll(sel).forEach((el) => {
      if (visible(el) && !found.includes(el)) found.push(el);
    });
  }
  // fallback: text input before password
  if (!found.length) {
    const pass = findPasswordFields()[0];
    if (pass) {
      const form = pass.closest('form') || document;
      const texts = [...form.querySelectorAll('input[type="text"], input:not([type])')].filter(visible);
      if (texts.length) found.push(texts[0]);
    }
  }
  return found;
}

function visible(el) {
  if (!el || el.disabled || el.readOnly) return false;
  const st = getComputedStyle(el);
  if (st.display === 'none' || st.visibility === 'hidden' || st.opacity === '0') return false;
  const r = el.getBoundingClientRect();
  return r.width > 0 && r.height > 0;
}

function setValue(el, value) {
  el.focus();
  el.value = value;
  el.dispatchEvent(new Event('input', { bubbles: true }));
  el.dispatchEvent(new Event('change', { bubbles: true }));
}
