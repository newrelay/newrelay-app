json.payload do
  json.summary do
    json.total_campaigns @summary[:total_campaigns]
    json.active @summary[:active]
    json.completed @summary[:completed]
    json.processing @summary[:processing]
    json.attributed_conversations @summary[:attributed_conversations]
  end
  json.filters do
    json.since @filters[:since]
    json.until @filters[:until]
  end
  json.campaigns do
    json.array! @campaigns do |campaign|
      json.id campaign[:id]
      json.display_id campaign[:display_id]
      json.title campaign[:title]
      json.description campaign[:description]
      json.campaign_type campaign[:campaign_type]
      json.campaign_status campaign[:campaign_status]
      json.scheduled_at campaign[:scheduled_at]
      json.created_at campaign[:created_at]
      json.audience_count campaign[:audience_count]
      json.conversations_count campaign[:conversations_count]
      json.inbox do
        if campaign[:inbox]
          json.id campaign[:inbox][:id]
          json.name campaign[:inbox][:name]
          json.channel_type campaign[:inbox][:channel_type]
        end
      end
    end
  end
end
