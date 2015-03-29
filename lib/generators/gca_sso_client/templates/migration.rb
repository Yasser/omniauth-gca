class CreateGcaSsoClientTables < ActiveRecord::Migration
  def change
    create_table :access_groups do |t|
      t.string   :key,         null: false
      t.string   :title,       null: false
      t.string   :group_key,   null: false
      t.string   :group_title, null: false
      t.datetime :created_at
      t.datetime :updated_at
    end

    create_table :access_groups_users, id: false do |t|
      t.integer :user_id,         null: false
      t.integer :access_group_id, null: false
    end

    create_table :users do |t|
      t.string   :email,       null: false
      t.datetime :created_at
      t.datetime :updated_at
      t.integer  :uid,         null: false
      t.string   :first_name,  null: false
      t.string   :last_name,   null: false
      t.string   :title
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip
      t.boolean  :admin
    end

    add_index :users, :uid, unique: true
  end
end