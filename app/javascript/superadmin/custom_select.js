const CHEVRON_SVG =
  '<svg class="nr-select-chevron" xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m6 9 6 6 6-6"/></svg>';
const CHECK_SVG =
  '<svg class="nr-select-check" xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>';

export function syncCustomSelect(selectEl) {
  if (!selectEl) return;
  const wrapper = selectEl.nextElementSibling;
  if (!wrapper || !wrapper.classList.contains('nr-select')) return;
  const label = wrapper.querySelector('.nr-select-label');
  const selectedOption = selectEl.options[selectEl.selectedIndex];
  if (label && selectedOption) label.textContent = selectedOption.text;
  wrapper.querySelectorAll('.nr-select-item').forEach(item => {
    item.classList.toggle(
      'selected',
      item.getAttribute('data-value') === selectEl.value
    );
  });
}

export function initCustomSelects() {
  document
    .querySelectorAll('select:not([multiple]):not([data-nr-native])')
    .forEach(select => {
      if (select.dataset.customized === 'true') return;
      // BelongsToSearch uses selectize AJAX typeahead (account show User picker).
      if (select.closest('.field-unit--belongs-to-search')) return;
      select.dataset.customized = 'true';
      select.classList.add('nr-select-native');

      const wrapper = document.createElement('div');
      wrapper.className = 'nr-select';
      if (select.id) wrapper.id = `nr-select-${select.id}`;

      const trigger = document.createElement('button');
      trigger.type = 'button';
      trigger.className = 'nr-select-trigger reset-base';
      trigger.setAttribute('aria-haspopup', 'listbox');
      trigger.setAttribute('aria-expanded', 'false');

      const label = document.createElement('span');
      label.className = 'nr-select-label';
      const selectedOption =
        select.options[select.selectedIndex] || select.options[0];
      label.textContent = selectedOption ? selectedOption.text : '';
      trigger.appendChild(label);
      trigger.insertAdjacentHTML('beforeend', CHEVRON_SVG);
      wrapper.appendChild(trigger);

      const menu = document.createElement('div');
      menu.className = 'nr-select-menu';
      menu.setAttribute('role', 'listbox');

      Array.from(select.options).forEach(opt => {
        const item = document.createElement('div');
        item.className = `nr-select-item${opt.selected ? ' selected' : ''}`;
        item.setAttribute('role', 'option');
        item.setAttribute('data-value', opt.value);
        const itemText = document.createElement('span');
        itemText.textContent = opt.text;
        item.appendChild(itemText);
        item.insertAdjacentHTML('beforeend', CHECK_SVG);
        item.addEventListener('click', e => {
          e.stopPropagation();
          select.value = opt.value;
          label.textContent = opt.text;
          menu
            .querySelectorAll('.nr-select-item')
            .forEach(el => el.classList.remove('selected'));
          item.classList.add('selected');
          wrapper.classList.remove('open');
          trigger.setAttribute('aria-expanded', 'false');
          select.dispatchEvent(new Event('change', { bubbles: true }));
        });
        menu.appendChild(item);
      });

      wrapper.appendChild(menu);
      trigger.addEventListener('click', e => {
        e.stopPropagation();
        const isOpen = wrapper.classList.contains('open');
        document
          .querySelectorAll('.nr-select.open, .filter-dropdown.open')
          .forEach(el => {
            if (el !== wrapper) el.classList.remove('open');
          });
        wrapper.classList.toggle('open', !isOpen);
        trigger.setAttribute('aria-expanded', String(!isOpen));
      });

      select.parentNode.insertBefore(wrapper, select.nextSibling);
    });
}

document.addEventListener('click', e => {
  if (!e.target.closest('.nr-select')) {
    document
      .querySelectorAll('.nr-select.open')
      .forEach(el => el.classList.remove('open'));
  }
});

document.addEventListener('change', e => {
  if (e.target && e.target.matches('select')) syncCustomSelect(e.target);
});

document.addEventListener('DOMContentLoaded', () => {
  initCustomSelects();
  window.initCustomSelects = initCustomSelects;
  window.syncCustomSelect = syncCustomSelect;
});
