json.id message_log.id
json.comment_id message_log.comment_id
json.commenter_id message_log.commenter_id
json.status message_log.status
json.sent_at message_log.sent_at&.to_i
json.created_at message_log.created_at.to_i

json.inbox do
  json.id message_log.inbox.id
  json.name message_log.inbox.name
  json.channel_type message_log.inbox.channel_type
end

json.campaign do
  json.id message_log.trigger.campaign.id
  json.name message_log.trigger.campaign.name
end

json.trigger do
  json.id message_log.trigger.id
  json.keyword message_log.trigger.keyword
end

if message_log.contact
  json.contact do
    json.id message_log.contact.id
    json.name message_log.contact.name
    json.avatar_url message_log.contact.avatar_url
  end
else
  json.contact nil
end
