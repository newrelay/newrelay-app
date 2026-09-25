json.id @order.id
json.status @order.status
json.provider_type @order.provider_type
json.provider_order_id @order.provider_order_id
json.phone_number @order.phone_number
json.country_code @order.country_code
json.created_at @order.created_at.to_i
json.updated_at @order.updated_at.to_i
