/**
 * Writes a text string to the system clipboard.
 *
 * @async
 * @param {string} data text to be written to the clipboard
 * @throws {Error} unable to copy text to clipboard
 */
export const copyTextToClipboard = async data => {
  const text =
    typeof data === 'object' && data !== null
      ? JSON.stringify(data, null, 2)
      : String(data ?? '');

  if (navigator.clipboard && navigator.clipboard.writeText) {
    try {
      await navigator.clipboard.writeText(text);
      return;
    } catch (error) {
      // Fall through to fallback method
    }
  }

  try {
    const textarea = document.createElement('textarea');
    textarea.value = text;
    textarea.style.top = '0';
    textarea.style.left = '0';
    textarea.style.position = 'fixed';
    textarea.style.opacity = '0';
    document.body.appendChild(textarea);
    textarea.focus();
    textarea.select();
    const successful = document.execCommand('copy');
    document.body.removeChild(textarea);
    if (!successful) {
      throw new Error('copy command was unsuccessful');
    }
  } catch (error) {
    throw new Error(`Unable to copy text to clipboard: ${error.message}`);
  }
};

/**
 * Handles OTP paste events by extracting numeric digits from clipboard data.
 *
 * @param {ClipboardEvent} event - The paste event from the clipboard
 * @param {number} maxLength - Maximum number of digits to extract (default: 6)
 * @returns {string|null} - Extracted numeric string or null if invalid
 */
export const handleOtpPaste = (event, maxLength = 6) => {
  if (!event?.clipboardData) return null;

  const pastedData = event.clipboardData
    .getData('text')
    .replace(/\D/g, '') // Remove all non-digit characters
    .slice(0, maxLength); // Limit to maxLength digits

  // Only return if we have the exact expected length
  return pastedData.length === maxLength ? pastedData : null;
};
