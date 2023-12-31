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

ActiveRecord::Schema[7.0].define(version: 2023_07_29_160912) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "messages", force: :cascade do |t|
    t.text "body"
    t.bigint "user_id"
    t.boolean "read", default: false
    t.boolean "from_admin", default: false
    t.boolean "requires_action", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "tournament_claims", force: :cascade do |t|
    t.integer "user_id"
    t.integer "tournament_id"
    t.text "reasoning"
    t.boolean "approved", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tournament_id", "user_id"], name: "index_tournament_claims_on_tournament_id_and_user_id", unique: true
    t.index ["tournament_id"], name: "index_tournament_claims_on_tournament_id"
    t.index ["user_id"], name: "index_tournament_claims_on_user_id"
  end

  create_table "tournaments", force: :cascade do |t|
    t.string "name"
    t.string "liquipedia_url"
    t.string "rules_url"
    t.string "registration_url"
    t.string "format"
    t.string "game"
    t.string "tier"
    t.string "prize_pool"
    t.text "restrictions"
    t.text "notes"
    t.string "organizers"
    t.integer "status", default: 0
    t.date "registration_close"
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "info_url"
    t.bigint "message_id"
    t.string "flags"
    t.index ["liquipedia_url"], name: "index_tournaments_on_liquipedia_url", unique: true
    t.index ["message_id"], name: "index_tournaments_on_message_id"
    t.index ["name"], name: "index_tournaments_on_name", unique: true
    t.index ["registration_close"], name: "index_tournaments_on_registration_close"
    t.index ["start_date"], name: "index_tournaments_on_start_date"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.boolean "admin", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "tournaments", "messages"
end
