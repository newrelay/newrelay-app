// Custom File Upload Component handler

const FILE_TRIGGER_ICON =
  '<svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" x2="12" y1="3" y2="15"/></svg>';

function bindFileInput(wrapper) {
  const hiddenInput = wrapper.querySelector('input[type="file"]');
  const nameLabel = wrapper.querySelector('.file-upload-name');
  const trigger = wrapper.querySelector('.file-upload-trigger');

  if (!hiddenInput || wrapper.dataset.nrFileBound === 'true') return;
  wrapper.dataset.nrFileBound = 'true';

  hiddenInput.classList.add('file-input-hidden');

  if (trigger) {
    trigger.addEventListener('click', event => {
      event.preventDefault();
      hiddenInput.click();
    });
  }

  if (nameLabel) {
    hiddenInput.addEventListener('change', () => {
      nameLabel.textContent =
        hiddenInput.files && hiddenInput.files.length > 0
          ? hiddenInput.files[0].name
          : 'No file chosen';
    });
  }
}

function wrapNativeFileInput(input) {
  if (
    input.closest('.custom-file-upload') ||
    input.dataset.nrNative !== undefined
  )
    return;

  const wrapper = document.createElement('div');
  wrapper.className = 'custom-file-upload';
  input.parentNode.insertBefore(wrapper, input);
  wrapper.appendChild(input);

  const trigger = document.createElement('button');
  trigger.type = 'button';
  trigger.className = 'file-upload-trigger reset-base';
  trigger.innerHTML = `${FILE_TRIGGER_ICON}<span>Choose file</span>`;

  const nameLabel = document.createElement('span');
  nameLabel.className = 'file-upload-name';
  nameLabel.textContent = 'No file chosen';

  wrapper.appendChild(trigger);
  wrapper.appendChild(nameLabel);
}

export function initCustomFileInputs() {
  document
    .querySelectorAll('input[type="file"]:not([data-nr-native])')
    .forEach(input => {
      wrapNativeFileInput(input);
    });

  document.querySelectorAll('.custom-file-upload').forEach(bindFileInput);
}

document.addEventListener('DOMContentLoaded', () => {
  initCustomFileInputs();
});
