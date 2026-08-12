namespace :plan_feature_limits do
  desc 'Seed PlanFeatureLimit rows (features + resource limits, incl. Captain AI credits) for Hobby, Standard & Business plans (Enterprise excluded)'
  task seed: :environment do
    Seeders::PlanFeatureLimitSeeder.new.perform!

    plan_keys = Seeders::PlanFeatureLimitSeeder::PLAN_KEYS
    count = PlanFeatureLimit.where(plan_key: plan_keys).count
    puts "Seeded #{count} PlanFeatureLimit rows for: #{plan_keys.join(', ')}."
    puts 'Enterprise was skipped — it is negotiated per-account via EnterpriseContract.'
  end

  desc 'Re-apply the current PlanFeatureLimit matrix (features + limits, incl. Captain AI credits) to every existing account'
  task reconcile_accounts: :environment do
    updated = 0
    skipped = 0
    failed = 0

    Account.find_each do |account|
      plan_key = account.custom_attributes['plan_name'].presence&.downcase
      next(skipped += 1) if plan_key.blank? || PlanFeatureLimit.where(plan_key: plan_key).none?

      begin
        Enterprise::Billing::ReconcilePlanFeaturesService.new(account: account).perform
        updated += 1
      rescue StandardError => e
        failed += 1
        puts "  ❌ Account ##{account.id} (#{plan_key}): #{e.message}"
      end
    end

    puts "Reconciled #{updated} account(s). Skipped #{skipped} (no plan / unknown plan_key). Failed #{failed}."
  end

  desc 'Push STRIPE_HOBBY_PRICE_ID / STRIPE_STANDARD_PRICE_ID / STRIPE_BUSINESS_PRICE_ID from .env into CHATWOOT_CLOUD_PLANS'
  task seed_stripe_prices: :environment do
    Seeders::StripePlanPriceSeeder.new.perform!

    plans = InstallationConfig.find_by(name: 'CHATWOOT_CLOUD_PLANS')&.value || []
    plans.each { |plan| puts "#{plan['name']}: price_ids=#{plan['price_ids']}" }
  end
end
