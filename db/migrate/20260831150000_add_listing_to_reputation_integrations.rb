class AddListingToReputationIntegrations < ActiveRecord::Migration[7.1]
  def up
    add_column :reputation_integrations, :reputation_listing_id, :bigint
    add_index :reputation_integrations, :reputation_listing_id

    # Backfill: attach each account's existing integrations to its primary
    # (or first) listing, since integrations predate this column and every
    # account so far has at most a handful of listings.
    execute <<~SQL.squish
      UPDATE reputation_integrations ri
      SET reputation_listing_id = (
        SELECT rl.id FROM reputation_listings rl
        WHERE rl.account_id = ri.account_id
        ORDER BY rl.primary DESC, rl.created_at ASC
        LIMIT 1
      )
      WHERE ri.reputation_listing_id IS NULL
    SQL
  end

  def down
    remove_index :reputation_integrations, :reputation_listing_id
    remove_column :reputation_integrations, :reputation_listing_id
  end
end
