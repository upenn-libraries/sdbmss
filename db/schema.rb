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

ActiveRecord::Schema.define(version: 20141218192403) do

  create_table "agents", force: true do |t|
    t.integer  "entry_id"
    t.integer  "viaf_id"
    t.string   "name"
    t.string   "agent_type"
    t.boolean  "approved"
    t.integer  "approved_by_id"
    t.datetime "approved_date"
  end

  add_index "agents", ["approved_by_id"], name: "index_agents_on_approved_by_id", using: :btree
  add_index "agents", ["entry_id"], name: "index_agents_on_entry_id", using: :btree
  add_index "agents", ["name"], name: "index_agents_on_name", unique: true, using: :btree

  create_table "artists", force: true do |t|
    t.string   "name"
    t.integer  "entry_id"
    t.boolean  "approved"
    t.integer  "approved_by_id"
    t.datetime "approved_date"
  end

  add_index "artists", ["approved_by_id"], name: "index_artists_on_approved_by_id", using: :btree
  add_index "artists", ["entry_id"], name: "index_artists_on_entry_id", using: :btree
  add_index "artists", ["name"], name: "index_artists_on_name", unique: true, using: :btree

  create_table "authors", force: true do |t|
    t.string   "name"
    t.integer  "entry_id"
    t.string   "viaf_id"
    t.boolean  "approved"
    t.integer  "approved_by_id"
    t.datetime "approved_date"
  end

  add_index "authors", ["approved_by_id"], name: "index_authors_on_approved_by_id", using: :btree
  add_index "authors", ["entry_id"], name: "index_authors_on_entry_id", using: :btree
  add_index "authors", ["name"], name: "index_authors_on_name", unique: true, using: :btree

  create_table "bookmarks", force: true do |t|
    t.integer  "user_id",       null: false
    t.string   "user_type"
    t.string   "document_id"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "document_type"
  end

  add_index "bookmarks", ["user_id"], name: "index_bookmarks_on_user_id", using: :btree

  create_table "entries", force: true do |t|
    t.string   "date"
    t.integer  "source_id"
    t.string   "catalog_or_lot_number"
    t.string   "secondary_source"
    t.string   "current_location"
    t.integer  "folios"
    t.integer  "num_columns"
    t.integer  "num_lines"
    t.integer  "height"
    t.integer  "width"
    t.string   "alt_size"
    t.string   "manuscript_binding",     limit: 512
    t.text     "other_info"
    t.string   "manuscript_link",        limit: 1024
    t.integer  "miniatures_fullpage"
    t.integer  "miniatures_large"
    t.integer  "miniatures_small"
    t.integer  "miniatures_unspec_size"
    t.integer  "initials_historiated"
    t.integer  "initials_decorated"
    t.datetime "added_on"
    t.integer  "added_by_id"
    t.boolean  "approved",                            default: false
    t.boolean  "deleted",                             default: false
    t.datetime "last_modified"
    t.integer  "last_modified_by_id"
  end

  add_index "entries", ["added_by_id"], name: "index_entries_on_added_by_id", using: :btree
  add_index "entries", ["last_modified_by_id"], name: "index_entries_on_last_modified_by_id", using: :btree
  add_index "entries", ["source_id"], name: "index_entries_on_source_id", using: :btree

  create_table "entry_artists", force: true do |t|
    t.integer "entry_id"
    t.integer "artist_id"
  end

  add_index "entry_artists", ["artist_id"], name: "index_entry_artists_on_artist_id", using: :btree
  add_index "entry_artists", ["entry_id"], name: "index_entry_artists_on_entry_id", using: :btree

  create_table "entry_authors", force: true do |t|
    t.integer  "entry_id"
    t.integer  "author_id"
    t.string   "observed_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "entry_authors", ["author_id"], name: "index_entry_authors_on_author_id", using: :btree
  add_index "entry_authors", ["entry_id"], name: "index_entry_authors_on_entry_id", using: :btree

  create_table "entry_changes", force: true do |t|
    t.integer  "entry_id"
    t.string   "column"
    t.text     "changed_from"
    t.text     "changed_to"
    t.string   "change_type"
    t.datetime "change_date"
    t.integer  "changed_by_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "entry_changes", ["changed_by_id"], name: "index_entry_changes_on_changed_by_id", using: :btree
  add_index "entry_changes", ["entry_id"], name: "index_entry_changes_on_entry_id", using: :btree

  create_table "entry_comments", force: true do |t|
    t.integer  "entry_id"
    t.text     "comment"
    t.boolean  "public"
    t.datetime "date"
    t.datetime "added_on"
    t.integer  "added_by_id"
  end

  add_index "entry_comments", ["added_by_id"], name: "index_entry_comments_on_added_by_id", using: :btree
  add_index "entry_comments", ["entry_id"], name: "index_entry_comments_on_entry_id", using: :btree

  create_table "entry_dates", force: true do |t|
    t.integer "entry_id"
    t.string  "date"
    t.string  "circa"
  end

  add_index "entry_dates", ["entry_id"], name: "index_entry_dates_on_entry_id", using: :btree

  create_table "entry_languages", force: true do |t|
    t.integer "entry_id"
    t.integer "language_id"
  end

  add_index "entry_languages", ["entry_id"], name: "index_entry_languages_on_entry_id", using: :btree
  add_index "entry_languages", ["language_id"], name: "index_entry_languages_on_language_id", using: :btree

  create_table "entry_manuscripts", force: true do |t|
    t.integer  "entry_id"
    t.integer  "manuscript_id"
    t.string   "relation_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "entry_manuscripts", ["entry_id"], name: "index_entry_manuscripts_on_entry_id", using: :btree
  add_index "entry_manuscripts", ["manuscript_id"], name: "index_entry_manuscripts_on_manuscript_id", using: :btree

  create_table "entry_materials", force: true do |t|
    t.integer "entry_id"
    t.string  "material"
  end

  add_index "entry_materials", ["entry_id"], name: "index_entry_materials_on_entry_id", using: :btree

  create_table "entry_places", force: true do |t|
    t.integer "entry_id"
    t.integer "place_id"
  end

  add_index "entry_places", ["entry_id"], name: "index_entry_places_on_entry_id", using: :btree
  add_index "entry_places", ["place_id"], name: "index_entry_places_on_place_id", using: :btree

  create_table "entry_scribes", force: true do |t|
    t.integer "entry_id"
    t.integer "scribe_id"
  end

  add_index "entry_scribes", ["entry_id"], name: "index_entry_scribes_on_entry_id", using: :btree
  add_index "entry_scribes", ["scribe_id"], name: "index_entry_scribes_on_scribe_id", using: :btree

  create_table "entry_titles", force: true do |t|
    t.integer "entry_id"
    t.string  "title",        limit: 2048
    t.string  "common_title", limit: 2048
  end

  add_index "entry_titles", ["entry_id"], name: "index_entry_titles_on_entry_id", using: :btree

  create_table "entry_uses", force: true do |t|
    t.integer "entry_id"
    t.string  "use"
  end

  add_index "entry_uses", ["entry_id"], name: "index_entry_uses_on_entry_id", using: :btree

  create_table "event_agents", force: true do |t|
    t.integer "event_id"
    t.string  "observed_name"
    t.integer "agent_id"
    t.string  "role"
  end

  add_index "event_agents", ["agent_id"], name: "index_event_agents_on_agent_id", using: :btree
  add_index "event_agents", ["event_id"], name: "index_event_agents_on_event_id", using: :btree
  add_index "event_agents", ["observed_name"], name: "index_event_agents_on_observed_name", using: :btree

  create_table "events", force: true do |t|
    t.integer "entry_id"
    t.boolean "primary",                                 default: false
    t.text    "comment"
    t.integer "order"
    t.string  "acquire_date"
    t.string  "end_date"
    t.decimal "price",          precision: 20, scale: 2
    t.string  "currency"
    t.string  "other_currency"
    t.string  "sold"
  end

  add_index "events", ["entry_id"], name: "index_events_on_entry_id", using: :btree

  create_table "languages", force: true do |t|
    t.string "name"
  end

  create_table "legacy_data_issues", force: true do |t|
    t.string  "table_name"
    t.integer "record_id"
    t.string  "issue_type"
    t.string  "explanation", limit: 1024
  end

  create_table "manuscripts", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "places", force: true do |t|
    t.string   "name"
    t.integer  "entry_id"
    t.boolean  "approved"
    t.integer  "approved_by_id"
    t.datetime "approved_date"
  end

  add_index "places", ["approved_by_id"], name: "index_places_on_approved_by_id", using: :btree
  add_index "places", ["entry_id"], name: "index_places_on_entry_id", using: :btree
  add_index "places", ["name"], name: "index_places_on_name", unique: true, using: :btree

  create_table "scribes", force: true do |t|
    t.string "name"
  end

  add_index "scribes", ["name"], name: "index_scribes_on_name", unique: true, using: :btree

  create_table "searches", force: true do |t|
    t.text     "query_params"
    t.integer  "user_id"
    t.string   "user_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "searches", ["user_id"], name: "index_searches_on_user_id", using: :btree

  create_table "sessions", force: true do |t|
    t.string   "session_id", null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", unique: true, using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "source_agents", force: true do |t|
    t.integer  "source_id"
    t.integer  "agent_id"
    t.string   "role"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "source_agents", ["agent_id"], name: "index_source_agents_on_agent_id", using: :btree
  add_index "source_agents", ["source_id"], name: "index_source_agents_on_source_id", using: :btree

  create_table "sources", force: true do |t|
    t.string   "date"
    t.string   "source_type"
    t.string   "title",                          limit: 512
    t.string   "author"
    t.string   "alt_date"
    t.string   "whether_mss"
    t.string   "current_location"
    t.string   "location_city"
    t.string   "location_country"
    t.string   "link",                           limit: 512
    t.string   "electronic_catalog_format"
    t.string   "electronic_catalog_open_access"
    t.boolean  "in_manuscript_table"
    t.boolean  "deleted"
    t.datetime "added_on"
    t.integer  "added_by_id"
    t.datetime "last_modified"
    t.integer  "last_modified_by_id"
    t.text     "comments"
    t.string   "cataloging_type"
    t.string   "status"
    t.string   "hidden"
  end

  add_index "sources", ["added_by_id"], name: "index_sources_on_added_by_id", using: :btree
  add_index "sources", ["last_modified_by_id"], name: "index_sources_on_last_modified_by_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "email",                  default: "",    null: false
    t.string   "encrypted_password",     default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "guest",                  default: false
    t.string   "username"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["username"], name: "index_users_on_username", unique: true, using: :btree

end
