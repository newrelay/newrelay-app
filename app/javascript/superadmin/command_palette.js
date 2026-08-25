let selectedIndex = 0;

function commandPages() {
  const node = document.getElementById('nrCommandPages');
  if (!node) return [];
  try {
    return JSON.parse(node.textContent || '[]');
  } catch (_err) {
    return [];
  }
}

function searchModalIsOpen() {
  const modal = document.getElementById('searchModal');
  return Boolean(modal && !modal.classList.contains('hidden'));
}

function resultLinks() {
  return Array.from(
    document.querySelectorAll('#searchResultsModal a[data-command-item]')
  );
}

function highlightSelected() {
  resultLinks().forEach((link, i) => {
    const active = i === selectedIndex;
    link.classList.toggle('bg-accent', active);
    link.setAttribute('aria-selected', active ? 'true' : 'false');
  });
  const current = resultLinks()[selectedIndex];
  if (current) current.scrollIntoView({ block: 'nearest' });
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

  selectedIndex = 0;

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
      link.setAttribute('data-command-item', '');
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
      jump.className = 'command-jump';
      jump.textContent = 'Jump';
      link.append(left, jump);
      return link;
    })
  );
  highlightSelected();
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
      return;
    }
    if (!searchModalIsOpen()) return;
    const links = resultLinks();
    if (e.key === 'ArrowDown' && links.length) {
      e.preventDefault();
      selectedIndex = (selectedIndex + 1) % links.length;
      highlightSelected();
    } else if (e.key === 'ArrowUp' && links.length) {
      e.preventDefault();
      selectedIndex = (selectedIndex - 1 + links.length) % links.length;
      highlightSelected();
    } else if (e.key === 'Enter' && links[selectedIndex]) {
      e.preventDefault();
      links[selectedIndex].click();
    }
  });
});
