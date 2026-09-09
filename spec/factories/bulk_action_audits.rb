FactoryBot.define do
  factory :bulk_action_audit do
    account
    user
    action_label { 'Add label (support)' }
    operation_type { 'add_tag' }
    status { :pending }
    statistics { { total: 0, success: 0 } }
  end
end
