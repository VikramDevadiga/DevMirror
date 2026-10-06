// ── Copy buttons on guide pages ──
document.querySelectorAll('.code .copy').forEach((btn) => {
  btn.addEventListener('click', async () => {
    const text = btn.previousElementSibling.textContent;
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
    btn.textContent = 'Copied';
    setTimeout(() => { btn.textContent = 'Copy'; }, 1600);
  });
});
