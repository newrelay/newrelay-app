json.id pipeline.id
json.name pipeline.name
json.position pipeline.position
json.account_id pipeline.account_id
json.stages do
  json.array! pipeline.pipeline_stages do |stage|
    json.id stage.id
    json.name stage.name
    json.position stage.position
    json.color stage.color
    json.is_won stage.is_won
    json.is_lost stage.is_lost
  end
end
