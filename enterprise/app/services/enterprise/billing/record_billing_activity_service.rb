class Enterprise::Billing::RecordBillingActivityService
  pattr_initialize [:account!, :action!, :message!, :status!, { user: nil, error_class: nil, payment_provider: nil, metadata: {} }]

  def perform
    BillingActivityLog.create!(
      account: account,
      user: user,
      action: action,
      status: status,
      error_class: error_class,
      message: message.to_s.truncate(2000),
      payment_provider: payment_provider,
      metadata: metadata.presence || {}
    )
  end
end
