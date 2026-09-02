json.id campaign.id
json.name campaign.name
json.post_id campaign.post_id
json.is_active campaign.is_active
json.created_at campaign.created_at.to_i
json.updated_at campaign.updated_at.to_i

json.inbox do
  json.id campaign.inbox.id
  json.name campaign.inbox.name
  json.channel_type campaign.inbox.channel_type
end

trigger = campaign.triggers.first
if trigger
  json.trigger do
    json.id trigger.id
    json.keyword trigger.keyword
    json.match_type trigger.match_type
    json.public_replies trigger.public_replies
    json.dm_text_body trigger.dm_text_body
  end
else
  json.trigger nil
end

json.responses_count trigger ? trigger.message_logs.count : 0
