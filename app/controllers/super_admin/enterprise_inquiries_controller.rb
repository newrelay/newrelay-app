# Lists accounts that have submitted an "Enterprise plan" inquiry from the
# dashboard (see Enterprise::Api::V1::AccountsController#enterprise_inquiry)
# and lets a super admin mark them as followed up on.
class SuperAdmin::EnterpriseInquiriesController < SuperAdmin::ApplicationController
  def index
    @accounts = Account.where("custom_attributes -> 'enterprise_inquiry' IS NOT NULL")
                       .includes(:enterprise_contract)
                       .order(Arel.sql(
                                "(custom_attributes -> 'enterprise_inquiry' ->> 'processed_at') IS NOT NULL, " \
                                "custom_attributes -> 'enterprise_inquiry' ->> 'requested_at' DESC"
                              ))
    @payment_gateways = Enterprise::Billing::PaymentGatewayRegistry.enabled_gateways
  end

  def mark_processed
    account = Account.find(params[:id])
    inquiry = (Enterprise::Billing::EnterpriseInquiryAttributes.enterprise_inquiry(account) || {}).merge(
      'processed_at' => Time.current.iso8601,
      'processed_by' => current_super_admin.email
    )
    Enterprise::Billing::EnterpriseInquiryAttributes.save_enterprise_inquiry!(account, inquiry)

    # rubocop:disable Rails/I18nLocaleTexts
    redirect_back(fallback_location: super_admin_enterprise_inquiries_path, notice: 'Inquiry marked as processed.')
    # rubocop:enable Rails/I18nLocaleTexts
  end

  # Declines the inquiry without granting a plan, recording a note so the reason is
  # visible later. Clears any unpaid Enterprise checkout so the account can pick a
  # self-serve plan again.
  def reject
    account = Account.find(params[:id])
    inquiry = (Enterprise::Billing::EnterpriseInquiryAttributes.enterprise_inquiry(account) || {}).merge(
      'rejected_at' => Time.current.iso8601,
      'rejected_by' => current_super_admin.email,
      'rejection_note' => params[:note]
    )
    Enterprise::Billing::EnterpriseInquiryAttributes.save_enterprise_inquiry!(account, inquiry)
    Enterprise::Billing::ClearEnterpriseInquiryService.new(account: account, remove_inquiry: false).perform

    # rubocop:disable Rails/I18nLocaleTexts
    redirect_back(fallback_location: super_admin_enterprise_inquiries_path, notice: 'Inquiry rejected.')
    # rubocop:enable Rails/I18nLocaleTexts
  end

  # Removes the inquiry from this list entirely (e.g. spam/duplicate submissions).
  # Doesn't touch any plan/contract the account may already have.
  def destroy
    account = Account.find(params[:id])
    Enterprise::Billing::ClearEnterpriseInquiryService.new(account: account).perform

    # rubocop:disable Rails/I18nLocaleTexts
    redirect_back(fallback_location: super_admin_enterprise_inquiries_path, notice: 'Inquiry deleted.')
    # rubocop:enable Rails/I18nLocaleTexts
  end

  def send_payment_link
    account = Account.find(params[:id])
    monthly_price = params[:monthly_price].presence || account.enterprise_contract&.negotiated_price
    inquiry = Enterprise::Billing::EnterpriseInquiryAttributes.enterprise_inquiry(account) || {}
    recipient_email = inquiry['requested_by']
    stored_attrs = Enterprise::Billing::EnterpriseInquiryAttributes.stored_custom_attributes(account)
    provider = params[:payment_provider].presence ||
               Enterprise::Billing::PaymentGatewayRegistry.resolve_provider(
                 country: stored_attrs['billing_country']
               )

    if monthly_price.blank? || recipient_email.blank?
      # rubocop:disable Rails/I18nLocaleTexts
      return redirect_back(fallback_location: super_admin_enterprise_inquiries_path, alert: 'A monthly price is required to send a payment link.')
      # rubocop:enable Rails/I18nLocaleTexts
    end

    result = Enterprise::Billing::EnterprisePaymentLinkService.new(
      account: account,
      monthly_price: monthly_price,
      success_url: ENV.fetch('FRONTEND_URL', root_url),
      cancel_url: ENV.fetch('FRONTEND_URL', root_url),
      provider: provider
    ).perform

    EnterpriseInquiryPaymentLinkMailer.with(account: account)
                                      .send_link(account: account, recipient_email: recipient_email, monthly_price: monthly_price,
                                                 payment_url: result[:checkout_url])
                                      .deliver_later

    Enterprise::Billing::EnterpriseInquiryAttributes.save_enterprise_inquiry!(
      account,
      inquiry.merge(
        'payment_link_url' => result[:checkout_url],
        'payment_link_amount' => monthly_price,
        'payment_link_provider' => result[:provider] || provider,
        'payment_link_sent_at' => Time.current.iso8601,
        'payment_link_sent_by' => current_super_admin.email
      )
    )

    redirect_back(fallback_location: super_admin_enterprise_inquiries_path, notice: "Payment link sent to #{recipient_email}.")
  rescue Stripe::StripeError, Enterprise::Billing::RazorpayClient::Error,
         Enterprise::Billing::RazorpayEnterprisePaymentLinkService::Error => e
    redirect_back(fallback_location: super_admin_enterprise_inquiries_path, alert: "Failed to create payment link: #{e.message}")
  end
end
