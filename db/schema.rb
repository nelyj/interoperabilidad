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

ActiveRecord::Schema.define(version: 20171218110243) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "unaccent"

  create_table "agreement_revisions", force: :cascade do |t|
    t.integer  "agreement_id",                  null: false
    t.integer  "user_id",                       null: false
    t.integer  "state",             default: 0, null: false
    t.text     "purpose"
    t.text     "legal_base"
    t.string   "log"
    t.string   "file"
    t.text     "objection_message"
    t.integer  "revision_number",               null: false
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.index ["agreement_id"], name: "index_agreement_revisions_on_agreement_id", using: :btree
    t.index ["user_id"], name: "index_agreement_revisions_on_user_id", using: :btree
  end

  create_table "agreements", force: :cascade do |t|
    t.integer  "service_provider_organization_id", null: false
    t.integer  "service_consumer_organization_id", null: false
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.string   "client_secret"
    t.index ["service_consumer_organization_id"], name: "index_agreements_on_service_consumer_organization_id", using: :btree
    t.index ["service_provider_organization_id"], name: "index_agreements_on_service_provider_organization_id", using: :btree
  end

  create_table "agreements_services", force: :cascade do |t|
    t.integer "agreement_id", null: false
    t.integer "service_id",   null: false
    t.index ["agreement_id"], name: "index_agreements_services_on_agreement_id", using: :btree
    t.index ["service_id"], name: "index_agreements_services_on_service_id", using: :btree
  end

  create_table "monitor_params", force: :cascade do |t|
    t.integer  "organization_id",                    null: false
    t.integer  "health_check_frequency", default: 1, null: false
    t.integer  "unavailable_threshold",  default: 5, null: false
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.index ["organization_id"], name: "index_monitor_params_on_organization_id", using: :btree
  end

  create_table "notifications", force: :cascade do |t|
    t.integer  "user_id",                      null: false
    t.string   "subject_type",                 null: false
    t.integer  "subject_id",                   null: false
    t.string   "message",                      null: false
    t.boolean  "read",         default: false
    t.boolean  "seen",         default: false
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.string   "email"
    t.index ["subject_type", "subject_id"], name: "index_notifications_on_subject_type_and_subject_id", using: :btree
    t.index ["user_id"], name: "index_notifications_on_user_id", using: :btree
  end

  create_table "organizations", force: :cascade do |t|
    t.string  "name",          null: false
    t.string  "initials"
    t.string  "dipres_id",     null: false
    t.integer "agreements_id"
    t.string  "address"
    t.index ["agreements_id"], name: "index_organizations_on_agreements_id", using: :btree
    t.index ["dipres_id"], name: "index_organizations_on_dipres_id", unique: true, using: :btree
  end

  create_table "roles", id: false, force: :cascade do |t|
    t.integer "user_id",         null: false
    t.integer "organization_id", null: false
    t.string  "name",            null: false
    t.string  "email"
    t.index ["organization_id"], name: "index_roles_on_organization_id", using: :btree
    t.index ["user_id"], name: "index_roles_on_user_id", using: :btree
  end

  create_table "schema_categories", force: :cascade do |t|
    t.string   "name",        null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "description"
  end

  create_table "schema_categories_schemas", force: :cascade do |t|
    t.integer "schema_id"
    t.integer "schema_category_id"
  end

  create_table "schema_versions", force: :cascade do |t|
    t.integer  "schema_id",               null: false
    t.integer  "version_number",          null: false
    t.jsonb    "spec",                    null: false
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.jsonb    "spec_with_resolved_refs"
    t.integer  "user_id",                 null: false
  end

  create_table "schemas", force: :cascade do |t|
    t.string   "name",           null: false
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.tsvector "lexemes"
    t.string   "humanized_name"
    t.index ["lexemes"], name: "schemas_lexemes_idx", using: :gin
    t.index ["name"], name: "index_schemas_on_name", using: :btree
  end

  create_table "service_version_health_checks", force: :cascade do |t|
    t.integer  "service_version_id"
    t.integer  "http_status"
    t.integer  "status_code"
    t.string   "status_message"
    t.string   "custom_status_message"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.text     "http_response"
    t.boolean  "healthy"
    t.index ["service_version_id"], name: "index_service_version_health_checks_on_service_version_id", using: :btree
  end

  create_table "service_versions", force: :cascade do |t|
    t.integer  "service_id",                              null: false
    t.integer  "version_number",                          null: false
    t.jsonb    "spec",                                    null: false
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.integer  "status",                  default: 0
    t.integer  "user_id",                                 null: false
    t.boolean  "backwards_compatible",    default: false, null: false
    t.jsonb    "spec_with_resolved_refs"
    t.text     "reject_message"
    t.integer  "availability_status",     default: 0
    t.string   "custom_mock_service"
    t.string   "changelog"
  end

  create_table "services", force: :cascade do |t|
    t.string   "name",                               null: false
    t.integer  "organization_id",                    null: false
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.boolean  "public",             default: false
    t.tsvector "lexemes"
    t.string   "humanized_name"
    t.boolean  "featured",           default: false
    t.string   "provider_id"
    t.string   "provider_secret"
    t.boolean  "monitoring_enabled", default: true
    t.boolean  "support_xml",        default: false
    t.index ["lexemes"], name: "services_lexemes_idx", using: :gin
  end

  create_table "users", force: :cascade do |t|
    t.string   "rut",                                null: false
    t.string   "sub",                                null: false
    t.string   "id_token",                           null: false
    t.string   "name"
    t.integer  "sign_in_count",      default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.boolean  "can_create_schemas", default: false, null: false
    t.index ["rut"], name: "index_users_on_rut", unique: true, using: :btree
    t.index ["sub"], name: "index_users_on_sub", unique: true, using: :btree
  end

  add_foreign_key "schema_categories_schemas", "schema_categories"
  add_foreign_key "schema_categories_schemas", "schemas"
  add_foreign_key "schema_versions", "schemas"
  add_foreign_key "schema_versions", "users"
  add_foreign_key "service_versions", "services"
  add_foreign_key "service_versions", "users"
  add_foreign_key "services", "organizations"
end
