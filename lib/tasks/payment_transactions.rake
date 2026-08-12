namespace :payment_transactions do
  desc 'Backfill payment transactions from Stripe invoices'
  task sync: :environment do
    # Prefer a global Stripe walk + metadata/customer matching. Per-account sync alone
    # misses invoices when the local stripe_customer_id is missing or out of date.
    imported = Enterprise::Billing::SyncPaymentTransactionsService.backfill_all!
    puts "Imported/updated #{imported} invoices from Stripe."

    Account.where("custom_attributes->>'stripe_customer_id' IS NOT NULL")
           .where.not("custom_attributes->>'stripe_customer_id' = ?", '')
           .find_each do |account|
      count = Enterprise::Billing::SyncPaymentTransactionsService.new(account: account).perform
      puts "Account ##{account.id} (#{account.name}): synced #{count} by customer id"
    end
  end
end
