class AddHideWatermarkToReputationWidgets < ActiveRecord::Migration[7.1]
  def change
    add_column :reputation_widgets, :hide_watermark, :boolean, default: false, null: false
  end
end
