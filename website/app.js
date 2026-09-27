document.addEventListener('DOMContentLoaded', () => {
  initDemo();
  initTabs();
  initCopyButtons();
  initDownloadToast();
});

const EMAIL = 'redropecompany@gmail.com';
const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
const sleep = ms => new Promise(r => setTimeout(r, ms));

// ── 1. HERO DEMO: type `vite --host`, then the phone discovers servers ──
function initDemo() {
  const cmd = document.getElementById('termCmd');
  const caret = document.getElementById('termCaret');
  const out = document.getElementById('termOut');
  const label = document.getElementById('scanLabel');
  const ipEl = document.getElementById('scanIp');
  const bar = document.getElementById('scanBar');
  const servers = [...document.querySelectorAll('.p-server')];
  const tap = document.getElementById('tapRing');
  if (!cmd || !out || !bar) return;

  const COMMAND = 'npx vite --host';

  const showFinal = () => {
    cmd.textContent = COMMAND;
    out.classList.add('show');
    bar.style.width = '100%';
    label.textContent = `LIVE SERVERS · ${servers.length}`;
    ipEl.textContent = '';
    servers.forEach(s => s.classList.add('show'));
  };

  if (reduceMotion) { showFinal(); return; }

  const reset = () => {
    cmd.textContent = '';
    out.classList.remove('show');
    bar.style.width = '0%';
    label.textContent = 'SCANNING FOR SERVERS…';
    ipEl.textContent = '192.168.1.1';
    servers.forEach(s => s.classList.remove('show', 'pressed'));
  };

  const scan = (duration) => new Promise(resolve => {
    const start = performance.now();
    const frame = (now) => {
      const p = Math.min((now - start) / duration, 1);
      bar.style.width = `${p * 100}%`;
      ipEl.textContent = `192.168.1.${Math.max(1, Math.round(p * 254))}`;
      servers.forEach(s => { if (p >= parseFloat(s.dataset.at)) s.classList.add('show'); });
      p < 1 ? requestAnimationFrame(frame) : resolve();
    };
    requestAnimationFrame(frame);
  });

  const tapFirst = async () => {
    const target = servers[0].querySelector('.p-open');
    const screen = tap.parentElement.getBoundingClientRect();
    const r = target.getBoundingClientRect();
    // getBoundingClientRect includes the mobile scale transform; undo it for positioning
    const scale = screen.width / tap.parentElement.offsetWidth || 1;
    tap.style.left = `${(r.left + r.width / 2 - screen.left) / scale}px`;
    tap.style.top = `${(r.top + r.height / 2 - screen.top) / scale}px`;
    tap.classList.remove('go');
    void tap.offsetWidth;
    tap.classList.add('go');
    await sleep(220);
    servers[0].classList.add('pressed');
  };

  const run = async () => {
    for (;;) {
      reset();
      caret.style.visibility = 'visible';
      await sleep(700);
      for (const ch of COMMAND) {
        cmd.textContent += ch;
        await sleep(55 + Math.random() * 50);
      }
      await sleep(450);
      caret.style.visibility = 'hidden';
      out.classList.add('show');
      await sleep(500);
      await scan(2200);
      label.textContent = `LIVE SERVERS · ${servers.length}`;
      ipEl.textContent = '';
      await sleep(900);
      await tapFirst();
      await sleep(3200);
    }
  };

  run();
}

// ── 2. SETUP TABS ──
function initTabs() {
  const tabs = [...document.querySelectorAll('[role="tab"]')];
  if (!tabs.length) return;

  const select = (tab) => {
    tabs.forEach(t => {
      const on = t === tab;
      t.setAttribute('aria-selected', on);
      t.tabIndex = on ? 0 : -1;
      document.getElementById(t.getAttribute('aria-controls')).hidden = !on;
    });
  };

  tabs.forEach((tab, i) => {
    tab.addEventListener('click', () => select(tab));
    tab.addEventListener('keydown', (e) => {
      const dir = e.key === 'ArrowRight' ? 1 : e.key === 'ArrowLeft' ? -1 : 0;
      if (!dir) return;
      const next = tabs[(i + dir + tabs.length) % tabs.length];
      select(next);
      next.focus();
    });
  });
}

// ── 3. COPY (commands + email) ──
async function copyText(text) {
  try {
    await navigator.clipboard.writeText(text);
  } catch {
    const ta = document.createElement('textarea');
    ta.value = text;
    document.body.appendChild(ta);
    ta.select();
    document.execCommand('copy');
    ta.remove();
  }
}

function flash(btn, label = 'Copied') {
  const original = btn.textContent;
  btn.textContent = label;
  setTimeout(() => { btn.textContent = original; }, 1600);
}

function initCopyButtons() {
  document.querySelectorAll('.code .copy').forEach(btn => {
    btn.addEventListener('click', async () => {
      await copyText(btn.previousElementSibling.textContent);
      flash(btn);
    });
  });

  const emailBtn = document.getElementById('copyEmailBtn');
  if (emailBtn) {
    emailBtn.addEventListener('click', async () => {
      await copyText(EMAIL);
      flash(emailBtn);
      showToast(`Copied ${EMAIL}`);
    });
  }
}

// ── 4. TOAST ──
let toastTimer;
function showToast(message) {
  const toast = document.getElementById('toast');
  if (!toast) return;
  toast.textContent = message;
  toast.classList.add('show');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => toast.classList.remove('show'), 2400);
}

function initDownloadToast() {
  document.querySelectorAll('.js-download').forEach(a => {
    a.addEventListener('click', () => showToast('Downloading DevMirror.apk…'));
  });
}
