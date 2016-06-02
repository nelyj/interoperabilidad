class DeviseCreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string :rut, null: false
      t.string :sub, null: false
      t.string :id_token, null: false
      t.string :name
      t.string :email

      ## Devise Trackable
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.inet     :current_sign_in_ip
      t.inet     :last_sign_in_ip

      t.timestamps null: false
    end

    add_index :users, :rut, unique: true
    add_index :users, :sub, unique: true
    add_index :users, :email
  end
end
