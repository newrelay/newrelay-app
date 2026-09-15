// Super Admin Navigation, Dark Mode Theme Toggle, Search Palette and Filter Dropdowns

export function initDarkMode() {
  const isDark = localStorage.getItem('nr-dark') === 'true';
  if (isDark) {
    document.documentElement.classList.add('dark');
  }
}

export function toggleDarkMode() {
  const isDark = document.documentElement.classList.toggle('dark');
  localStorage.setItem('nr-dark', isDark);
  window.dispatchEvent(new Event('nr-theme-changed'));
}

export function initSidebarToggle() {
  const trigger = document.getElementById('sidebarTrigger');
  const sidebar = document.getElementById('sidebar');
  const spacer = document.getElementById('sidebarSpacer');
  const overlay = document.getElementById('sidebarOverlay');

  if (trigger && sidebar) {
    trigger.addEventListener('click', () => {
      const isMobile = window.innerWidth < 768;
      if (isMobile) {
        const isOpen = sidebar.classList.toggle('mobile-open');
        if (overlay) overlay.classList.toggle('active', isOpen);
      } else {
        const isCollapsed = sidebar.classList.toggle('collapsed');
        sidebar.setAttribute('data-collapsed', isCollapsed ? 'true' : 'false');
        if (spacer) spacer.classList.toggle('collapsed', isCollapsed);
        window.dispatchEvent(new Event('resize'));
      }
    });
  }
}

export function closeMobileSidebar() {
  const sidebar = document.getElementById('sidebar');
  const overlay = document.getElementById('sidebarOverlay');
  if (sidebar) sidebar.classList.remove('mobile-open');
  if (overlay) overlay.classList.remove('active');
}

export function initSubmenu() {
  document.querySelectorAll('.sidebar-menu-item').forEach(item => {
    const trigger = item.querySelector('.sidebar-menu-btn');
    if (trigger) {
      trigger.addEventListener('click', e => {
        if (
          e.target.closest('.sidebar-menu-sub') ||
          e.target.closest('.sidebar-flyout')
        )
          return;
        const isChevron = e.target.closest('.sidebar-chevron');
        if (isChevron) {
          e.preventDefault();
          e.stopPropagation();
          const isOpen = item.classList.toggle('open');
          trigger.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
        } else if (trigger.tagName === 'BUTTON') {
          const isOpen = item.classList.toggle('open');
          trigger.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
        }
      });
    }
  });
}

export function toggleFilterDropdown(dropdownId) {
  const dropdown = document.getElementById(dropdownId);
  if (!dropdown) return;
  const isOpen = dropdown.classList.contains('open');
  document
    .querySelectorAll('.filter-dropdown.open')
    .forEach(d => d.classList.remove('open'));
  if (!isOpen) {
    dropdown.classList.add('open');
  }
}

export function selectFilter(dropdownId, value, label, callbackFn) {
  const dropdown = document.getElementById(dropdownId);
  if (!dropdown) return;

  const labelEl = dropdown.querySelector('.filter-label');
  if (labelEl) labelEl.textContent = label;

  const trigger = dropdown.querySelector('.filter-dropdown-trigger');
  if (trigger) trigger.classList.toggle('active', value !== 'all');

  dropdown.querySelectorAll('.filter-dropdown-item').forEach(item => {
    item.classList.toggle('selected', item.dataset.value === value);
  });

  dropdown.classList.remove('open');
  if (typeof callbackFn === 'function') callbackFn(value);
}

// Global initialization
document.addEventListener('DOMContentLoaded', () => {
  initDarkMode();
  initSidebarToggle();
  initSubmenu();

  document.addEventListener('click', e => {
    if (!e.target.closest('.filter-dropdown')) {
      document
        .querySelectorAll('.filter-dropdown.open')
        .forEach(d => d.classList.remove('open'));
    }
  });

  window.toggleDarkMode = toggleDarkMode;
  window.closeMobileSidebar = closeMobileSidebar;
  window.toggleFilterDropdown = toggleFilterDropdown;
  window.selectFilter = selectFilter;

  const passwordToggle = document.querySelector('[data-password-toggle]');
  const passwordInput = document.querySelector('#super_admin_password');
  if (passwordToggle && passwordInput) {
    passwordToggle.addEventListener('click', () => {
      const show = passwordInput.type === 'password';
      passwordInput.type = show ? 'text' : 'password';
      passwordToggle.setAttribute(
        'aria-label',
        show
          ? passwordToggle.dataset.labelHide
          : passwordToggle.dataset.labelShow
      );
      passwordToggle
        .querySelector('[data-password-icon="show"]')
        ?.classList.toggle('hidden', show);
      passwordToggle
        .querySelector('[data-password-icon="hide"]')
        ?.classList.toggle('hidden', !show);
    });
  }
});
