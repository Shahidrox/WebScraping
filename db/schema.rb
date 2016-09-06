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

ActiveRecord::Schema.define(version: 20160628055126) do

  create_table "all_cards", force: :cascade do |t|
    t.integer  "rank"
    t.string   "merchant"
    t.string   "card_type"
    t.integer  "quantity"
    t.float    "value"
    t.float    "discount"
    t.string   "seller"
    t.float    "one_and_one"
    t.float    "one_and_gcs"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "card_details", force: :cascade do |t|
    t.string   "day"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "cards", force: :cascade do |t|
    t.integer  "card_detail_id"
    t.integer  "rank"
    t.string   "merchant"
    t.string   "card_type"
    t.integer  "quantity"
    t.float    "value"
    t.float    "discount"
    t.string   "seller"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.float    "one_and_one"
    t.float    "one_and_gcs"
  end

  add_index "cards", ["card_detail_id"], name: "index_cards_on_card_detail_id"

  create_table "merchants", force: :cascade do |t|
    t.string   "name"
    t.string   "granny_url"
    t.string   "website"
    t.integer  "ecodes_available"
    t.float    "max_savings"
    t.float    "average_savings"
    t.integer  "cards_available"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  create_table "sellers", force: :cascade do |t|
    t.integer  "seller_id"
    t.string   "seller_name"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true

end
