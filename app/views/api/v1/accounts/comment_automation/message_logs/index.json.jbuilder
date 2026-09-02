json.payload do
  json.array! @message_logs do |message_log|
    json.partial! 'api/v1/accounts/comment_automation/message_logs/partials/message_log', formats: [:json], message_log: message_log
  end
end
