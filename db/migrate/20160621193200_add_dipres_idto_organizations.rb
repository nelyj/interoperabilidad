class AddDipresIdtoOrganizations < ActiveRecord::Migration[5.0]
  def up
    add_column :organizations, :dipres_id, :string, unique: true
    execute 'UPDATE organizations SET dipres_id = id'
    change_column_null :organizations, :dipres_id, false

    add_index :organizations, :dipres_id, unique: true
  end

  def down
    remove_column :organizations, :dipres_id
  end
end
