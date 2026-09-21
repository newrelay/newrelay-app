class AddInboxScopeToEmailTemplates < ActiveRecord::Migration[7.1]
  def up
    add_column :email_templates, :inbox_id, :integer unless column_exists?(:email_templates, :inbox_id)
    add_index :email_templates, :inbox_id, name: 'index_email_templates_on_inbox_id' unless index_exists?(
      :email_templates, :inbox_id, name: 'index_email_templates_on_inbox_id'
    )

    remove_index :email_templates, name: 'index_email_templates_on_name_and_account_id', if_exists: true
    ensure_no_duplicate_installation_templates!

    add_unique_index_unless_exists(
      :email_templates,
      %i[name template_type locale],
      name: 'index_email_templates_on_installation_scope',
      where: 'account_id IS NULL AND inbox_id IS NULL'
    )
    add_unique_index_unless_exists(
      :email_templates,
      %i[account_id name template_type locale],
      name: 'index_email_templates_on_account_scope',
      where: 'account_id IS NOT NULL AND inbox_id IS NULL'
    )
    add_unique_index_unless_exists(
      :email_templates,
      %i[inbox_id name template_type locale],
      name: 'index_email_templates_on_inbox_scope',
      where: 'inbox_id IS NOT NULL'
    )
  end

  def down
    remove_index :email_templates, name: 'index_email_templates_on_inbox_scope', if_exists: true
    remove_index :email_templates, name: 'index_email_templates_on_account_scope', if_exists: true
    remove_index :email_templates, name: 'index_email_templates_on_installation_scope', if_exists: true
    remove_index :email_templates, name: 'index_email_templates_on_inbox_id', if_exists: true

    unless index_exists?(:email_templates, %i[name account_id], name: 'index_email_templates_on_name_and_account_id')
      add_index :email_templates, %i[name account_id], unique: true, name: 'index_email_templates_on_name_and_account_id'
    end

    remove_column :email_templates, :inbox_id if column_exists?(:email_templates, :inbox_id)
  end

  private

  def add_unique_index_unless_exists(table, columns, name:, where:)
    return if index_exists?(table, columns, name: name)

    add_index table, columns, unique: true, where: where, name: name
  end

  def ensure_no_duplicate_installation_templates!
    duplicates = select_values <<~SQL.squish
      SELECT CONCAT(name, '/', template_type, '/', locale)
      FROM email_templates
      WHERE account_id IS NULL
      GROUP BY name, template_type, locale
      HAVING COUNT(*) > 1
    SQL
    return if duplicates.empty?

    raise ActiveRecord::IrreversibleMigration,
          "Duplicate installation email templates must be resolved before migrating: #{duplicates.join(', ')}"
  end
end
