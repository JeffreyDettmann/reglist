# frozen_string_literal: true

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

ActiveRecord::Schema[7.0].define(version: 20_230_624_011_253) do
  # These are extensions that must be enabled in order to support this database
  enable_extension 'plpgsql'

  create_table 'tournaments', force: :cascade do |t|
    t.string 'name'
    t.string 'liquipedia_url'
    t.string 'rules_url'
    t.string 'registration_url'
    t.string 'format'
    t.string 'game'
    t.string 'tier'
    t.string 'prize_pool'
    t.text 'restrictions'
    t.text 'notes'
    t.string 'organizers'
    t.integer 'status', default: 0
    t.date 'registration_close'
    t.date 'start_date'
    t.date 'end_date'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['name'], name: 'index_tournaments_on_name'
    t.index ['registration_close'], name: 'index_tournaments_on_registration_close'
    t.index ['start_date'], name: 'index_tournaments_on_start_date'
  end
end
