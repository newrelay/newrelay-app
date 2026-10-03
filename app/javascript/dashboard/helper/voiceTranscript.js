const STAGE_DIRECTION = /^(?:\[[a-z]{2,20}\]\s*)+/i;

export const spokenTranscript = text =>
  String(text || '').replace(STAGE_DIRECTION, '');
