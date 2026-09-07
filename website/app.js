// ── INITIALIZATION & EVENT LISTENERS ──
document.addEventListener('DOMContentLoaded', () => {
  initComparisonToggle();
  initEmailCopy();
  initDownloadHandler();
});

// ── 1. COMPARISON VIEW TOGGLE ──
function initComparisonToggle() {
  const toggleButtons = document.querySelectorAll('#viewToggle .toggle-btn');
  const grid = document.getElementById('comparisonGrid');

  if (!grid) return;

  toggleButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      toggleButtons.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');

      const view = btn.getAttribute('data-view');
      grid.setAttribute('data-active-view', view);
    });
  });
}

// ── 2. EMAIL COPY & TOAST ──
function initEmailCopy() {
  const copyBtn = document.getElementById('copyEmailBtn');
  const copyText = document.getElementById('copyBtnText');
  const email = 'redropecompany@gmail.com';

  if (!copyBtn) return;

  copyBtn.addEventListener('click', async () => {
    try {
      await navigator.clipboard.writeText(email);
      if (copyText) copyText.textContent = 'Copied!';
      showToast('Email copied to clipboard: ' + email);

      setTimeout(() => {
        if (copyText) copyText.textContent = 'Copy';
      }, 2000);
    } catch (err) {
      // Fallback
      const textArea = document.createElement('textarea');
      textArea.value = email;
      document.body.appendChild(textArea);
      textArea.select();
      document.execCommand('copy');
      document.body.removeChild(textArea);
      
      if (copyText) copyText.textContent = 'Copied!';
      showToast('Email copied to clipboard: ' + email);

      setTimeout(() => {
        if (copyText) copyText.textContent = 'Copy';
      }, 2000);
    }
  });
}

function showToast(message) {
  const toast = document.getElementById('toast');
  if (!toast) return;

  toast.textContent = message;
  toast.classList.add('show');

  setTimeout(() => {
    toast.classList.remove('show');
  }, 2500);
}

// ── 3. DOWNLOAD HANDLER ──
function initDownloadHandler() {
  const downloadBtns = document.querySelectorAll('.btn-download, .btn-primary[download]');
  downloadBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      showToast('Downloading DevMirror.apk (v1.0)...');
    });
  });
}
