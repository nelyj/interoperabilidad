class CreateOrganizations < ActiveRecord::Migration[5.0]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :initials
    end

    create_table :users_organizations, id: false do |t|
      t.belongs_to :user, index: true
      t.belongs_to :organization, index: true
    end
  end
end
