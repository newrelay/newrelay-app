const brief = value => {
  const text = String(value || '').trim();
  return text && text.length <= 80 ? text : '';
};

export const voiceSummary = voice => {
  const traits = String(voice?.traits || '')
    .split(',')
    .map(part => part.trim().replace(/_/g, ' '))
    .filter(Boolean)
    .slice(0, 3);
  return [brief(voice?.tone), traits.join(', '), brief(voice?.persona)]
    .filter(Boolean)
    .join(' · ');
};

export const filterVoices = (voices, query) => {
  const needle = String(query || '')
    .trim()
    .toLowerCase();
  if (!needle) return voices;
  return voices.filter(voice =>
    [voice.name, voice.tone, voice.persona, voice.traits, voiceSummary(voice)]
      .filter(Boolean)
      .join(' ')
      .toLowerCase()
      .includes(needle)
  );
};
