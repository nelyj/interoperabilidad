# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160606214923) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "organizations", force: :cascade do |t|
    t.string "name",     null: false
    t.string "initials"
  end

  create_table "roles", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "organization_id"
    t.index ["organization_id"], name: "index_roles_on_organization_id", using: :btree
    t.index ["user_id"], name: "index_roles_on_user_id", using: :btree
  end

  create_table "schema_categories", force: :cascade do |t|
    t.string   "name",       null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "schema_versions", force: :cascade do |t|
    t.integer  "schema_id",      null: false
    t.integer  "version_number", null: false
    t.jsonb    "spec",           null: false
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  create_table "schemas", force: :cascade do |t|
    t.string   "name",               null: false
    t.integer  "schema_category_id", null: false
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.index ["name"], name: "index_schemas_on_name", using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.string   "rut",                                null: false
    t.string   "sub",                                null: false
    t.string   "id_token",                           null: false
    t.string   "name"
    t.string   "email"
    t.integer  "sign_in_count",      default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.boolean  "can_create_schemas", default: false, null: false
    t.index ["email"], name: "index_users_on_email", using: :btree
    t.index ["rut"], name: "index_users_on_rut", unique: true, using: :btree
    t.index ["sub"], name: "index_users_on_sub", unique: true, using: :btree
  end

  add_foreign_key "schema_versions", "schemas"
  add_foreign_key "schemas", "schema_categories"
end
