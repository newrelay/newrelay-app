class AddScopesAndLastUsedAtToAccessTokens < ActiveRecord::Migration[7.1]
  def change
    add_column :access_tokens, :scopes, :string, array: true, default: [], null: false, if_not_exists: true
    add_column :access_tokens, :last_used_at, :datetime, if_not_exists: true
  end
end
