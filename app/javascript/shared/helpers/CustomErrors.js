/* eslint-disable max-classes-per-file */
export class DuplicateContactException extends Error {
  static DEFAULT_MESSAGE = 'DUPLICATE_CONTACT';

  constructor(data) {
    super(DuplicateContactException.DEFAULT_MESSAGE);
    this.data = data;
    this.name = 'DuplicateContactException';
  }

  /** Server or client may assign `message` after construction; otherwise still DEFAULT_MESSAGE. */
  get contactErrorDetail() {
    return this.message === DuplicateContactException.DEFAULT_MESSAGE
      ? null
      : this.message;
  }
}
export class ExceptionWithMessage extends Error {
  constructor(data) {
    super('ERROR_WITH_MESSAGE');
    this.data = data;
    this.name = 'ExceptionWithMessage';
  }
}

/**
 * Pulls a human-readable message out of an API error response.
 *
 * Most error responses use `{ message: "..." }` or `{ error: "..." }` with a
 * plain string, but some (e.g. Rails validation errors) send `{ error: {
 * field: ["is invalid"] } }` with a Hash instead. Only string values are
 * safe to show directly in a toast — anything else falls back to `null` so
 * callers can use a generic message instead of dumping raw JSON in the UI.
 * @param {*} error - the caught axios error
 * @returns {string|null}
 */
export const extractResponseMessage = error => {
  const responseMessage =
    error?.response?.data?.message || error?.response?.data?.error;
  return typeof responseMessage === 'string' ? responseMessage : null;
};
