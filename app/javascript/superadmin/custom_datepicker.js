/* eslint-disable no-use-before-define */
/* Enhances native date / datetime-local / time inputs in Super Admin with the
   Design-System-NR single-date popover (calendar + time column). The native
   input stays in the DOM as the real submitted field (hidden via
   `.nr-date-native`); the visible UI is a trigger button + popover. Mirrors the
   enhancer pattern in custom_select.js — no external libraries. */

const CAL_ICON =
  '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18M8 2v4M16 2v4"/></svg>';
const CLOCK_ICON =
  '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/></svg>';
const CHEVRON_LEFT =
  '<svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m15 18-6-6 6-6"/></svg>';
const CHEVRON_RIGHT =
  '<svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m9 18 6-6-6-6"/></svg>';

const MONTHS = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
const MONTHS_SHORT = MONTHS.map(m => m.slice(0, 3));
// Monday-first week to match the mock.
const WEEKDAYS = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

const pad = value => String(value).padStart(2, '0');

const modeForInput = input => {
  const type = (input.getAttribute('type') || '').toLowerCase();
  if (type === 'date') return 'date';
  if (type === 'time') return 'time';
  return 'datetime';
};

const parseInitial = (value, mode) => {
  const state = { date: null, hour: 0, minute: 0 };
  if (!value) return state;

  if (mode === 'time') {
    const [h, m] = value.split(':');
    state.hour = Number(h) || 0;
    state.minute = Number(m) || 0;
    state.hasTime = true;
    return state;
  }

  const [datePart, timePart] = value.split('T');
  const [y, mo, d] = datePart.split('-').map(Number);
  if (y && mo && d) state.date = new Date(y, mo - 1, d);
  if (mode === 'datetime' && timePart) {
    const [h, m] = timePart.split(':');
    state.hour = Number(h) || 0;
    state.minute = Number(m) || 0;
    state.hasTime = true;
  }
  return state;
};

const to12h = hour => ({
  hour12: ((hour + 11) % 12) + 1,
  period: hour < 12 ? 'AM' : 'PM',
});

const to24h = (hour12, period) => {
  const base = hour12 % 12;
  return period === 'PM' ? base + 12 : base;
};

function enhance(input) {
  const mode = modeForInput(input);
  const state = parseInitial(input.value, mode);
  let viewDate = state.date ? new Date(state.date) : new Date();

  input.dataset.customized = 'true';
  input.classList.add('nr-date-native');

  const wrap = document.createElement('div');
  wrap.className = 'date-input-wrap';

  const trigger = document.createElement('button');
  trigger.type = 'button';
  trigger.className = 'nr-date-trigger reset-base';

  const iconBtn = document.createElement('button');
  iconBtn.type = 'button';
  iconBtn.className = 'date-input-btn reset-base';
  iconBtn.innerHTML = mode === 'time' ? CLOCK_ICON : CAL_ICON;

  const popover = document.createElement('div');
  popover.className = 'single-datepicker-popover';

  const panels = document.createElement('div');
  panels.className = 'datepicker-panels';
  popover.appendChild(panels);

  input.parentNode.insertBefore(wrap, input);
  wrap.appendChild(trigger);
  wrap.appendChild(iconBtn);
  wrap.appendChild(input);
  wrap.appendChild(popover);

  const formatDisplay = () => {
    if (mode === 'time') {
      if (!state.hasTime) return '';
      const { hour12, period } = to12h(state.hour);
      return `${pad(hour12)}:${pad(state.minute)} ${period}`;
    }
    if (!state.date) return '';
    const d = state.date;
    const base = `${pad(d.getDate())} ${MONTHS_SHORT[d.getMonth()]} ${d.getFullYear()}`;
    if (mode === 'datetime') {
      const { hour12, period } = to12h(state.hour);
      return `${base}, ${pad(hour12)}:${pad(state.minute)} ${period}`;
    }
    return base;
  };

  const updateTrigger = () => {
    const label = formatDisplay();
    trigger.textContent = label || trigger.dataset.placeholder || 'Select';
    trigger.classList.toggle('is-placeholder', !label);
  };
  trigger.dataset.placeholder = mode === 'time' ? 'Select time' : 'Select date';

  const writeValue = () => {
    if (mode === 'time') {
      input.value = state.hasTime
        ? `${pad(state.hour)}:${pad(state.minute)}`
        : '';
    } else if (!state.date) {
      input.value = '';
    } else {
      const d = state.date;
      let v = `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
      if (mode === 'datetime') v += `T${pad(state.hour)}:${pad(state.minute)}`;
      input.value = v;
    }
    input.dispatchEvent(new Event('change', { bubbles: true }));
    updateTrigger();
  };

  const renderCalendar = () => {
    const col = document.createElement('div');
    col.className = 'datepicker-cal-col';

    const header = document.createElement('div');
    header.className = 'datepicker-header';
    const title = document.createElement('div');
    title.className = 'datepicker-month-year';
    title.textContent = `${MONTHS[viewDate.getMonth()]} ${viewDate.getFullYear()}`;
    const navBtns = document.createElement('div');
    navBtns.className = 'datepicker-nav-btns';
    const prev = document.createElement('button');
    prev.type = 'button';
    prev.className = 'datepicker-nav-btn reset-base';
    prev.innerHTML = CHEVRON_LEFT;
    prev.addEventListener('click', () => {
      viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth() - 1, 1);
      render();
    });
    const next = document.createElement('button');
    next.type = 'button';
    next.className = 'datepicker-nav-btn reset-base';
    next.innerHTML = CHEVRON_RIGHT;
    next.addEventListener('click', () => {
      viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth() + 1, 1);
      render();
    });
    navBtns.appendChild(prev);
    navBtns.appendChild(next);
    header.appendChild(title);
    header.appendChild(navBtns);
    col.appendChild(header);

    const weekdays = document.createElement('div');
    weekdays.className = 'datepicker-weekdays';
    WEEKDAYS.forEach(day => {
      const cell = document.createElement('div');
      cell.textContent = day;
      weekdays.appendChild(cell);
    });
    col.appendChild(weekdays);

    const grid = document.createElement('div');
    grid.className = 'datepicker-days-grid';
    const year = viewDate.getFullYear();
    const month = viewDate.getMonth();
    const firstDay = new Date(year, month, 1);
    const leading = (firstDay.getDay() + 6) % 7; // Monday-first offset
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const today = new Date();
    const isSameDay = (a, b) =>
      a &&
      b &&
      a.getFullYear() === b.getFullYear() &&
      a.getMonth() === b.getMonth() &&
      a.getDate() === b.getDate();

    const totalCells = Math.ceil((leading + daysInMonth) / 7) * 7;
    for (let i = 0; i < totalCells; i += 1) {
      const dayNumber = i - leading + 1;
      const cell = document.createElement('div');
      cell.className = 'datepicker-day-cell';
      if (dayNumber < 1 || dayNumber > daysInMonth) {
        cell.classList.add('other-month');
        const overflowDate = new Date(year, month, dayNumber);
        cell.textContent = overflowDate.getDate();
      } else {
        const cellDate = new Date(year, month, dayNumber);
        cell.textContent = dayNumber;
        if (isSameDay(cellDate, state.date)) cell.classList.add('selected');
        else if (isSameDay(cellDate, today)) cell.classList.add('today');
        cell.addEventListener('click', () => {
          state.date = cellDate;
          if (mode === 'datetime') state.hasTime = true;
          writeValue();
          if (mode === 'date') close();
          else render();
        });
      }
      grid.appendChild(cell);
    }
    col.appendChild(grid);

    const footer = document.createElement('div');
    footer.className = 'datepicker-footer-actions';
    const clearBtn = document.createElement('button');
    clearBtn.type = 'button';
    clearBtn.className = 'datepicker-footer-btn reset-base';
    clearBtn.textContent = 'Clear';
    clearBtn.addEventListener('click', () => {
      state.date = null;
      state.hasTime = false;
      writeValue();
      render();
    });
    const todayBtn = document.createElement('button');
    todayBtn.type = 'button';
    todayBtn.className = 'datepicker-footer-btn reset-base';
    todayBtn.textContent = 'Today';
    todayBtn.addEventListener('click', () => {
      const now = new Date();
      state.date = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      viewDate = new Date(state.date);
      if (mode === 'datetime') state.hasTime = true;
      writeValue();
      if (mode === 'date') close();
      else render();
    });
    footer.appendChild(clearBtn);
    footer.appendChild(todayBtn);
    col.appendChild(footer);

    panels.appendChild(col);
  };

  const renderTime = () => {
    const col = document.createElement('div');
    col.className = 'datepicker-time-col';

    const cols = document.createElement('div');
    cols.className = 'dp-time-cols';
    const { hour12, period } = to12h(state.hour);

    const hourScroll = document.createElement('div');
    hourScroll.className = 'dp-time-scroll';
    const hourLabel = document.createElement('div');
    hourLabel.className = 'dp-time-scroll-label';
    hourLabel.textContent = 'Hr';
    hourScroll.appendChild(hourLabel);
    for (let h = 1; h <= 12; h += 1) {
      const cell = document.createElement('div');
      cell.className = 'dp-time-cell';
      cell.textContent = pad(h);
      if (state.hasTime && h === hour12) cell.classList.add('selected');
      cell.addEventListener('click', () => {
        state.hour = to24h(h, to12h(state.hour).period);
        state.hasTime = true;
        writeValue();
        render();
      });
      hourScroll.appendChild(cell);
    }

    const minuteScroll = document.createElement('div');
    minuteScroll.className = 'dp-time-scroll';
    const minuteLabel = document.createElement('div');
    minuteLabel.className = 'dp-time-scroll-label';
    minuteLabel.textContent = 'Min';
    minuteScroll.appendChild(minuteLabel);
    for (let m = 0; m < 60; m += 1) {
      const cell = document.createElement('div');
      cell.className = 'dp-time-cell';
      cell.textContent = pad(m);
      if (state.hasTime && m === state.minute) cell.classList.add('selected');
      cell.addEventListener('click', () => {
        state.minute = m;
        state.hasTime = true;
        writeValue();
        render();
      });
      minuteScroll.appendChild(cell);
    }

    cols.appendChild(hourScroll);
    cols.appendChild(minuteScroll);
    col.appendChild(cols);

    const ampmRow = document.createElement('div');
    ampmRow.className = 'dp-ampm-row';
    ['AM', 'PM'].forEach(p => {
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'dp-ampm-btn reset-base';
      btn.textContent = p;
      if (state.hasTime && p === period) btn.classList.add('active');
      btn.addEventListener('click', () => {
        state.hour = to24h(to12h(state.hour).hour12, p);
        state.hasTime = true;
        writeValue();
        render();
      });
      ampmRow.appendChild(btn);
    });
    col.appendChild(ampmRow);

    panels.appendChild(col);
  };

  const render = () => {
    panels.innerHTML = '';
    if (mode !== 'time') renderCalendar();
    if (mode !== 'date') renderTime();
  };

  function close() {
    wrap.classList.remove('open');
    popover.classList.remove('active');
    trigger.setAttribute('aria-expanded', 'false');
  }

  const open = () => {
    document
      .querySelectorAll('.single-datepicker-popover.active')
      .forEach(el => {
        if (el !== popover) {
          el.classList.remove('active');
          el.closest('.date-input-wrap')?.classList.remove('open');
        }
      });
    if (state.date) viewDate = new Date(state.date);
    render();
    wrap.classList.add('open');
    popover.classList.add('active');
    trigger.setAttribute('aria-expanded', 'true');
  };

  const toggle = event => {
    event.stopPropagation();
    if (popover.classList.contains('active')) close();
    else open();
  };
  trigger.addEventListener('click', toggle);
  iconBtn.addEventListener('click', toggle);

  updateTrigger();
}

export function initCustomDatepickers() {
  document
    .querySelectorAll(
      'input[type="date"]:not([data-nr-native]):not([data-customized]),' +
        'input[type="datetime-local"]:not([data-nr-native]):not([data-customized]),' +
        'input[type="time"]:not([data-nr-native]):not([data-customized])'
    )
    .forEach(input => {
      if (input.dataset.customized === 'true') return;
      enhance(input);
    });
}

document.addEventListener('click', event => {
  if (!event.target.closest('.date-input-wrap')) {
    document
      .querySelectorAll('.single-datepicker-popover.active')
      .forEach(el => {
        el.classList.remove('active');
        el.closest('.date-input-wrap')?.classList.remove('open');
      });
  }
});

document.addEventListener('keydown', event => {
  if (event.key !== 'Escape') return;
  document.querySelectorAll('.single-datepicker-popover.active').forEach(el => {
    el.classList.remove('active');
    el.closest('.date-input-wrap')?.classList.remove('open');
  });
});

document.addEventListener('DOMContentLoaded', () => {
  initCustomDatepickers();
  window.initCustomDatepickers = initCustomDatepickers;
});
