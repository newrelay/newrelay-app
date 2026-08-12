class SuperAdmin::BillingCouponsController < SuperAdmin::ApplicationController
  # After create/update, sync the coupon to Stripe so Checkout can attach a real
  # gateway coupon id + metadata. Razorpay gets coupon metadata on subscription notes
  # and a discounted plan amount at checkout time.
  def new
    resource = resource_class.new(
      code: BillingCoupon.generate_code,
      discount_type: 'percent',
      duration: 'once',
      applies_to: 'plan',
      currency: 'usd',
      active: true
    )
    authorize_resource(resource)
    render locals: { page: Administrate::Page::Form.new(dashboard, resource) }
  end

  def create
    resource = resource_class.new(resource_params)
    authorize_resource(resource)

    if resource.save
      sync_to_gateways(resource)
      redirect_to(
        after_resource_created_path(resource),
        notice: translate_with_resource('create.success')
      )
    else
      render :new, locals: { page: Administrate::Page::Form.new(dashboard, resource) }, status: :unprocessable_entity
    end
  rescue Enterprise::Billing::SyncBillingCouponService::Error => e
    resource.errors.add(:base, e.message)
    render :new, locals: { page: Administrate::Page::Form.new(dashboard, resource) }, status: :unprocessable_entity
  end

  def update
    if requested_resource.update(resource_params)
      sync_to_gateways(requested_resource) if requested_resource.stripe_coupon_id.blank?
      redirect_to(
        after_resource_updated_path(requested_resource),
        notice: translate_with_resource('update.success')
      )
    else
      render :edit, locals: { page: Administrate::Page::Form.new(dashboard, requested_resource) }, status: :unprocessable_entity
    end
  rescue Enterprise::Billing::SyncBillingCouponService::Error => e
    requested_resource.errors.add(:base, e.message)
    render :edit, locals: { page: Administrate::Page::Form.new(dashboard, requested_resource) }, status: :unprocessable_entity
  end

  private

  def sync_to_gateways(coupon)
    Enterprise::Billing::SyncBillingCouponService.new(coupon: coupon).perform
  end
end
