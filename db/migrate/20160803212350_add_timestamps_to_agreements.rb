class AddTimestampsToAgreements < ActiveRecord::Migration[5.0]
  def change
    add_column :agreements, :created_at, :datetime
    add_column :agreements, :updated_at, :datetime
  end
end
