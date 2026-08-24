function commandPages() {
  const node = document.getElementById('nrCommandPages');
  if (!node) return [];
  try {
    return JSON.parse(node.textContent || '[]');
  } catch (_err) {
    return [];
  }
}

export function handleSearchModalInput(query) {
  const container = document.getElementById('searchResultsModal');
  if (!container) return;
  const q = (query || '').toLowerCase().trim();
  const pages = commandPages().filter(
    p =>
      !q ||
      p.label.toLowerCase().includes(q) ||
      (p.desc || '').toLowerCase().includes(q)
  );

  if (!pages.length) {
    const empty = document.createElement('div');
    empty.className = 'p-4 text-center text-xs text-muted-foreground';
    empty.textContent = `No pages found matching "${query}"`;
    container.replaceChildren(empty);
    return;
  }

  container.replaceChildren(
    ...pages.map(item => {
      const link = document.createElement('a');
      link.href = item.href;
      link.className =
        'flex items-center justify-between gap-3 px-3 py-2 rounded-md hover:bg-accent transition-colors';
      const left = document.createElement('div');
      const title = document.createElement('div');
      title.className = 'text-[13.5px] font-medium text-foreground';
      title.textContent = item.label;
      const desc = document.createElement('div');
      desc.className = 'text-xs text-muted-foreground';
      desc.textContent = item.desc || '';
      left.append(title, desc);
      const jump = document.createElement('span');
      jump.className =
        'shrink-0 rounded bg-muted px-1.5 py-0.5 text-[11px] text-muted-foreground';
      jump.textContent = 'Jump';
      link.append(left, jump);
      return link;
    })
  );
}
export function openSearchModal() {
  const modal = document.getElementById('searchModal');
  if (!modal) return;
  modal.classList.remove('hidden');
  modal.classList.add('flex');
  const input = document.getElementById('searchInputModal');
  if (input) {
    input.value = '';
    input.focus();
  }
  handleSearchModalInput('');
}

export function closeSearchModal() {
  const modal = document.getElementById('searchModal');
  if (!modal) return;
  modal.classList.add('hidden');
  modal.classList.remove('flex');
}

document.addEventListener('DOMContentLoaded', () => {
  window.openSearchModal = openSearchModal;
  window.closeSearchModal = closeSearchModal;
  window.handleSearchModalInput = handleSearchModalInput;

  document.addEventListener('keydown', e => {
    if (e.key === 'Escape') closeSearchModal();
    if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') {
      e.preventDefault();
      openSearchModal();
    }
  });
});
