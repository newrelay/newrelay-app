class AddConfigToReputationWidgets < ActiveRecord::Migration[7.1]
  def change
    add_column :reputation_widgets, :config, :jsonb, null: false, default: {}
  end
end
