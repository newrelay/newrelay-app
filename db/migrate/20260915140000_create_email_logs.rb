class CreateEmailLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :email_logs do |t|
      t.string :mailer_class, null: false
      t.string :to, null: false
      t.string :from
      t.string :subject
      t.text :body

      t.timestamps
    end
  end
end
