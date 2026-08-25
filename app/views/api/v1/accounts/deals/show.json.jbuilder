json.payload do
  json.partial! 'api/v1/accounts/deals/deal', deal: @deal
end
