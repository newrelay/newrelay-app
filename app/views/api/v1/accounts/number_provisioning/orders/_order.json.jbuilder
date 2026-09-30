json.id order.id
json.status order.status
json.unfinished !order.finished?
json.failure_message order.failure_message
json.provider_type order.provider_type
json.provider_order_id order.provider_order_id
json.phone_number order.phone_number
json.country_code order.country_code
json.created_at order.created_at.to_i
json.updated_at order.updated_at.to_i
if order.voice_agent
  json.voice_agent do
    json.status order.voice_agent.status
    json.failure_code order.voice_agent.failure_code
    json.twilio_connected order.voice_agent.elevenlabs_phone_number_id.present?
  end
else
  json.voice_agent nil
end
