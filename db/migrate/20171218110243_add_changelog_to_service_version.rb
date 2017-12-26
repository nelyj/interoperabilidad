class AddChangelogToServiceVersion < ActiveRecord::Migration[5.0]
  def change
    add_column :service_versions, :changelog, :string
  end
end