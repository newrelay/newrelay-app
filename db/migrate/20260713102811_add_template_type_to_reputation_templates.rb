class AddTemplateTypeToReputationTemplates < ActiveRecord::Migration[7.1]
  def change
    add_column :reputation_templates, :template_type, :string, default: 'standard', null: false
  end
end
