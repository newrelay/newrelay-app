class AddNegotiatedFeaturesToEnterpriseContracts < ActiveRecord::Migration[7.1]
  def change
    add_column :enterprise_contracts, :negotiated_features, :jsonb, default: []
  end
end
