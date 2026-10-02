class Twilio::ElevenlabsVoiceRow
  def self.live(row, local)
    blocked = row['requires_verification'] == true || local&.requires_verification?
    {
      voice_id: row['voice_id'],
      name: row['name'].presence || local&.name,
      preview_url: row['preview_url'].presence || local&.preview_url,
      requires_verification: blocked,
      selectable: row['voice_id'].present? && !blocked,
      status: local&.status || 'ready',
      error_message: local&.error_message
    }.merge(copy(row, local))
  end

  def self.local(item)
    {
      voice_id: item.voice_id,
      name: item.name,
      preview_url: item.preview_url,
      requires_verification: item.requires_verification,
      selectable: item.ready? && item.voice_id.present? && !item.requires_verification,
      status: item.status,
      error_message: item.error_message
    }.merge(copy({}, item))
  end

  def self.copy(row, local)
    labels = row['labels'].is_a?(Hash) ? row['labels'] : {}
    {
      tone: local&.tone.presence || labels['description'].presence,
      persona: local&.persona.presence || row['description'].presence,
      traits: labels.values_at('accent', 'age', 'gender', 'use_case').compact_blank.join(', ')
    }
  end
end
