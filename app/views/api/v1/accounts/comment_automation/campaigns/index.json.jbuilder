json.payload do
  json.array! @campaigns do |campaign|
    json.partial! 'api/v1/accounts/comment_automation/campaigns/partials/campaign', formats: [:json], campaign: campaign
  end
end
