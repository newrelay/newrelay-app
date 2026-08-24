let pendingDeleteAction = null;

export function closeDeleteModal() {
  const modal = document.getElementById('deleteConfirmModal');
  if (modal) modal.classList.remove('active');
  pendingDeleteAction = null;
}

export function openDeleteModal({
  title = 'Delete',
  itemName = 'this record',
  message,
  confirmText = 'Delete',
  cancelText = 'Keep',
  onConfirm,
} = {}) {
  const modal = document.getElementById('deleteConfirmModal');
  if (!modal) return;
  document.getElementById('deleteModalTitle').textContent = title;
  const desc = document.getElementById('deleteModalDesc');
  if (message) {
    desc.textContent = message;
  } else {
    desc.textContent = '';
    desc.appendChild(
      document.createTextNode('Are you sure you want to delete ')
    );
    const strong = document.createElement('strong');
    strong.textContent = itemName;
    desc.appendChild(strong);
    desc.appendChild(document.createTextNode('? This cannot be undone.'));
  }
  document.getElementById('deleteModalCancel').textContent = cancelText;
  document.getElementById('deleteModalConfirm').textContent = confirmText;
  pendingDeleteAction = onConfirm;
  modal.classList.add('active');
}

function confirmMessageFrom(el) {
  return (
    el.getAttribute('data-confirm') || el.getAttribute('data-turbo-confirm')
  );
}

function nounFromConfirm(message) {
  const match = (message || '').match(/delete\s+(?:the\s+)?(.+?)(?:\?|$)/i);
  if (!match) return 'record';
  return match[1].replace(/\s+from\s+.*/i, '').trim() || 'record';
}

export function initDeleteConfirm() {
  const modal = document.getElementById('deleteConfirmModal');
  if (!modal) return;

  document
    .getElementById('deleteModalCancel')
    .addEventListener('click', closeDeleteModal);
  document
    .getElementById('deleteModalConfirm')
    .addEventListener('click', () => {
      const action = pendingDeleteAction;
      closeDeleteModal();
      if (typeof action === 'function') action();
    });
  modal.addEventListener('click', e => {
    if (e.target === modal) closeDeleteModal();
  });

  document.addEventListener(
    'click',
    e => {
      const el = e.target.closest('[data-confirm], [data-turbo-confirm]');
      if (!el || el.dataset.nrConfirmSkip === 'true') return;
      const message = confirmMessageFrom(el);
      if (!message) return;
      e.preventDefault();
      e.stopImmediatePropagation();
      const noun = nounFromConfirm(message);
      openDeleteModal({
        title: `Delete ${noun}`,
        itemName: noun,
        message,
        confirmText: `Delete ${noun}`,
        cancelText: `Keep ${noun}`,
        onConfirm: () => {
          el.dataset.nrConfirmSkip = 'true';
          el.removeAttribute('data-confirm');
          el.removeAttribute('data-turbo-confirm');
          el.click();
        },
      });
    },
    true
  );

  document.addEventListener(
    'submit',
    e => {
      const form = e.target;
      if (
        !(form instanceof HTMLFormElement) ||
        form.dataset.nrConfirmSkip === 'true'
      )
        return;
      const message = confirmMessageFrom(form);
      if (!message) return;
      e.preventDefault();
      e.stopImmediatePropagation();
      const noun = nounFromConfirm(message);
      openDeleteModal({
        title: `Delete ${noun}`,
        itemName: noun,
        message,
        confirmText: `Delete ${noun}`,
        cancelText: `Keep ${noun}`,
        onConfirm: () => {
          form.dataset.nrConfirmSkip = 'true';
          form.removeAttribute('data-confirm');
          form.removeAttribute('data-turbo-confirm');
          form.requestSubmit();
        },
      });
    },
    true
  );
}

document.addEventListener('DOMContentLoaded', () => {
  initDeleteConfirm();
  window.openDeleteModal = openDeleteModal;
  window.closeDeleteModal = closeDeleteModal;
});

document.addEventListener('keydown', e => {
  if (e.key === 'Escape') closeDeleteModal();
});
