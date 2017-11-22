class CreateMonitorParams < ActiveRecord::Migration[5.0]
  def change
    create_table :monitor_params do |t|
      t.references :organization, null: false, index: true
      t.integer :health_check_frequency, null: false, default: 1
      t.integer :unavailable_threshold, null: false, default: 5

      t.timestamps
    end
  end
end
