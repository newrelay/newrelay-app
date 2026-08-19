class MakePortalSlugOptional < ActiveRecord::Migration[6.1]
  def change
    change_column_null :portals, :slug, true
  end
end
