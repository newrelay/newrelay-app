json.payload do
  json.array! @templates do |template|
    json.partial! 'api/v1/accounts/comment_automation/templates/partials/template', formats: [:json], template: template
  end
end
