// Custom File Upload Component handler

export function initCustomFileInputs() {
  document.querySelectorAll('.custom-file-upload').forEach(wrapper => {
    const hiddenInput = wrapper.querySelector('.file-input-hidden');
    const nameLabel = wrapper.querySelector('.file-upload-name');

    if (hiddenInput && nameLabel) {
      hiddenInput.addEventListener('change', () => {
        if (hiddenInput.files && hiddenInput.files.length > 0) {
          nameLabel.textContent = hiddenInput.files[0].name;
        } else {
          nameLabel.textContent = 'No file chosen';
        }
      });
    }
  });
}

document.addEventListener('DOMContentLoaded', () => {
  initCustomFileInputs();
});
