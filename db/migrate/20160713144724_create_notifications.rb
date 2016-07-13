class CreateNotifications < ActiveRecord::Migration[5.0]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, index: true
      t.references :subject, null: false, polymorphic: true, index: true
      t.string :message, null: false
      t.boolean :read, default: false
      t.boolean :seen, default: false
      t.timestamps
    end
  end
end
