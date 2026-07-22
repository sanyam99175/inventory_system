# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_06_05_191339) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "record_type"
    t.integer "record_id"
    t.string "action"
    t.jsonb "details"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "organization_id"
    t.index ["organization_id"], name: "index_audit_logs_on_organization_id"
  end

  create_table "demand_items", force: :cascade do |t|
    t.bigint "demand_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["demand_id"], name: "index_demand_items_on_demand_id"
    t.index ["product_id"], name: "index_demand_items_on_product_id"
  end

  create_table "demands", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "supplier_id", null: false
    t.integer "status", default: 0
    t.date "demand_date"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "purchase_id"
    t.datetime "converted_at"
    t.index ["organization_id"], name: "index_demands_on_organization_id"
    t.index ["purchase_id"], name: "index_demands_on_purchase_id"
    t.index ["supplier_id"], name: "index_demands_on_supplier_id"
  end

  create_table "histories", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "product_id", null: false
    t.integer "quantity_change"
    t.string "godown_number"
    t.datetime "requested_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "organization_id", null: false
    t.index ["organization_id"], name: "index_histories_on_organization_id"
    t.index ["product_id"], name: "index_histories_on_product_id"
    t.index ["user_id"], name: "index_histories_on_user_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "organization_id", null: false
    t.integer "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_memberships_on_organization_id"
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "notification_preferences", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.boolean "email"
    t.boolean "whatsapp"
    t.boolean "low_stock_alert"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "organization_id", null: false
    t.index ["organization_id"], name: "index_notification_preferences_on_organization_id"
    t.index ["user_id"], name: "index_notification_preferences_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "request_id", null: false
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "organization_id", null: false
    t.index ["organization_id"], name: "index_notifications_on_organization_id"
    t.index ["request_id"], name: "index_notifications_on_request_id"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "plan", default: "free"
    t.string "stripe_customer_id"
    t.string "stripe_subscription_id"
    t.string "subscription_status"
    t.datetime "trial_ends_at"
    t.boolean "trial_used"
    t.string "account_status", default: "active"
  end

  create_table "product_types", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "organization_id", null: false
    t.index ["organization_id"], name: "index_product_types_on_organization_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.integer "stock_count"
    t.string "godown_number"
    t.integer "alert_limit"
    t.bigint "product_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.bigint "organization_id", null: false
    t.bigint "supplier_id"
    t.index ["deleted_at"], name: "index_products_on_deleted_at"
    t.index ["organization_id"], name: "index_products_on_organization_id"
    t.index ["product_type_id"], name: "index_products_on_product_type_id"
    t.index ["supplier_id"], name: "index_products_on_supplier_id"
  end

  create_table "purchase_items", force: :cascade do |t|
    t.bigint "purchase_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity"
    t.decimal "unit_price"
    t.decimal "total_price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_purchase_items_on_product_id"
    t.index ["purchase_id"], name: "index_purchase_items_on_purchase_id"
  end

  create_table "purchases", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "supplier_id", null: false
    t.bigint "user_id", null: false
    t.string "invoice_number"
    t.date "purchase_date"
    t.decimal "subtotal"
    t.decimal "discount"
    t.decimal "tax"
    t.decimal "total_amount"
    t.decimal "paid_amount"
    t.decimal "due_amount"
    t.string "status"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "demand_id"
    t.index ["demand_id"], name: "index_purchases_on_demand_id"
    t.index ["organization_id"], name: "index_purchases_on_organization_id"
    t.index ["supplier_id"], name: "index_purchases_on_supplier_id"
    t.index ["user_id"], name: "index_purchases_on_user_id"
  end

  create_table "requests", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "user_id"
    t.integer "quantity_change"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "user_name"
    t.string "product_name"
    t.string "godown_number"
    t.bigint "organization_id", null: false
    t.index ["organization_id"], name: "index_requests_on_organization_id"
    t.index ["product_id"], name: "index_requests_on_product_id"
    t.index ["user_id"], name: "index_requests_on_user_id"
  end

  create_table "stock_requests", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "product_id", null: false
    t.integer "quantity"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "organization_id", null: false
    t.index ["organization_id"], name: "index_stock_requests_on_organization_id"
    t.index ["product_id"], name: "index_stock_requests_on_product_id"
    t.index ["user_id"], name: "index_stock_requests_on_user_id"
  end

  create_table "supplier_payments", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "supplier_id", null: false
    t.bigint "purchase_id", null: false
    t.bigint "user_id", null: false
    t.decimal "amount"
    t.string "payment_method"
    t.string "reference_number"
    t.date "paid_on"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_supplier_payments_on_organization_id"
    t.index ["purchase_id"], name: "index_supplier_payments_on_purchase_id"
    t.index ["supplier_id"], name: "index_supplier_payments_on_supplier_id"
    t.index ["user_id"], name: "index_supplier_payments_on_user_id"
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "name"
    t.string "phone"
    t.string "email"
    t.string "gst_number"
    t.text "address"
    t.text "notes"
    t.boolean "active"
    t.bigint "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_suppliers_on_organization_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name"
    t.integer "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.jsonb "permissions", default: {}, null: false
    t.bigint "organization_id"
    t.boolean "superadmin", default: false
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["superadmin"], name: "index_users_on_superadmin"
  end

  create_table "webhook_events", force: :cascade do |t|
    t.string "stripe_event_id"
    t.string "event_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "audit_logs", "organizations"
  add_foreign_key "demand_items", "demands"
  add_foreign_key "demand_items", "products"
  add_foreign_key "demands", "organizations"
  add_foreign_key "demands", "suppliers"
  add_foreign_key "histories", "organizations"
  add_foreign_key "histories", "products"
  add_foreign_key "histories", "users"
  add_foreign_key "memberships", "organizations"
  add_foreign_key "memberships", "users"
  add_foreign_key "notification_preferences", "organizations"
  add_foreign_key "notification_preferences", "users"
  add_foreign_key "notifications", "organizations"
  add_foreign_key "notifications", "requests"
  add_foreign_key "notifications", "users"
  add_foreign_key "product_types", "organizations"
  add_foreign_key "products", "organizations"
  add_foreign_key "products", "product_types"
  add_foreign_key "products", "suppliers"
  add_foreign_key "purchase_items", "products"
  add_foreign_key "purchase_items", "purchases"
  add_foreign_key "purchases", "demands"
  add_foreign_key "purchases", "organizations"
  add_foreign_key "purchases", "suppliers"
  add_foreign_key "purchases", "users"
  add_foreign_key "requests", "organizations"
  add_foreign_key "requests", "products"
  add_foreign_key "requests", "users"
  add_foreign_key "stock_requests", "organizations"
  add_foreign_key "stock_requests", "products"
  add_foreign_key "stock_requests", "users"
  add_foreign_key "supplier_payments", "organizations"
  add_foreign_key "supplier_payments", "purchases"
  add_foreign_key "supplier_payments", "suppliers"
  add_foreign_key "supplier_payments", "users"
  add_foreign_key "suppliers", "organizations"
  add_foreign_key "users", "organizations"
end
