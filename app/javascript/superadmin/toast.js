export function showToast(message, variant = 'success') {
  const container = document.getElementById('toastContainer');
  if (!container || !message) return;

  const el = document.createElement('div');
  el.className = `toast toast-${variant}`;
  el.setAttribute('role', 'status');
  el.textContent = message;
  container.appendChild(el);

  window.setTimeout(() => {
    el.classList.add('toast-out');
    window.setTimeout(() => el.remove(), 180);
  }, 2500);
}

function initToasts() {
  window.showToast = showToast;

  document.addEventListener('click', e => {
    if (e.target.closest('[data-secret-copier]')) {
      showToast('Copied to clipboard');
    }
  });
}

document.addEventListener('DOMContentLoaded', initToasts);
