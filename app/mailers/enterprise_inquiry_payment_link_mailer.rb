# Emails an Enterprise plan prospect the Stripe payment link a super admin
# generated for them from Super Admin > Enterprise Inquiries. Unlike
# AdministratorNotifications::EnterpriseInquiryMailer (which notifies the
# instance admin), this goes to the external requester.
class EnterpriseInquiryPaymentLinkMailer < ApplicationMailer
  def send_link(account:, recipient_email:, monthly_price:, payment_url:)
    return unless smtp_config_set_or_development?

    @account = account
    @monthly_price = monthly_price
    @action_url = payment_url

    send_mail_with_liquid(
      to: recipient_email,
      subject: "Your #{account.name} Enterprise plan payment link"
    )
  end

  private

  def liquid_locals
    super.merge(monthly_price: @monthly_price, account_name: @account.name)
  end
end
