class AddWhiteLabelToEmailTemplates < ActiveRecord::Migration[7.1]
  def up
    add_column :email_templates, :white_label, :boolean, default: false, null: false unless column_exists?(
      :email_templates, :white_label
    )

    remove_index :email_templates, name: 'index_email_templates_on_installation_scope', if_exists: true

    add_index :email_templates, %i[name template_type locale], unique: true,
              name: 'index_email_templates_on_installation_scope',
              where: 'account_id IS NULL AND inbox_id IS NULL AND white_label = FALSE'
    add_index :email_templates, %i[name template_type locale], unique: true,
              name: 'index_email_templates_on_white_label_scope',
              where: 'account_id IS NULL AND inbox_id IS NULL AND white_label = TRUE'
  end

  def down
    remove_index :email_templates, name: 'index_email_templates_on_white_label_scope', if_exists: true
    remove_index :email_templates, name: 'index_email_templates_on_installation_scope', if_exists: true

    add_index :email_templates, %i[name template_type locale], unique: true,
              name: 'index_email_templates_on_installation_scope',
              where: 'account_id IS NULL AND inbox_id IS NULL'

    remove_column :email_templates, :white_label if column_exists?(:email_templates, :white_label)
  end
end
