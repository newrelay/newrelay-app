class CreateChannelTelnyxAndExotelSms < ActiveRecord::Migration[7.1]
  def change
    create_provider_channel(:channel_telnyx_sms)
    create_provider_channel(:channel_exotel_sms)
  end

  private

  # inbox.channel_id is an integer, so these primary keys stay integer too.
  def create_provider_channel(table_name)
    create_table table_name, id: :integer do |t|
      t.integer :account_id, null: false
      t.string :phone_number, null: false
      t.timestamps
    end
    add_index table_name, :phone_number, unique: true
    add_index table_name, :account_id
  end
end
