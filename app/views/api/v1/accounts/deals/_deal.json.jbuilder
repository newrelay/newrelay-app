json.id deal.id
json.name deal.name
json.amount_cents deal.amount_cents
json.currency deal.currency
json.close_on deal.close_on
json.priority deal.priority
json.probability deal.probability
json.pipeline_id deal.pipeline_id
json.pipeline_stage_id deal.pipeline_stage_id
json.contact_id deal.contact_id
json.company_id deal.company_id
json.owner_id deal.owner_id
json.account_id deal.account_id
json.updated_at deal.updated_at
json.created_at deal.created_at
json.pipeline_stage do
  if deal.pipeline_stage
    json.id deal.pipeline_stage.id
    json.name deal.pipeline_stage.name
    json.color deal.pipeline_stage.color
    json.is_won deal.pipeline_stage.is_won
    json.is_lost deal.pipeline_stage.is_lost
  end
end
json.owner do
  if deal.owner
    json.id deal.owner.id
    json.name deal.owner.name
    json.available_name deal.owner.available_name
    json.thumbnail deal.owner.avatar_url
  end
end
json.contact do
  if deal.contact
    json.id deal.contact.id
    json.name deal.contact.name
  end
end

json.company do
  if deal.respond_to?(:company) && deal.company
    json.id deal.company.id
    json.name deal.company.name
  end
end

