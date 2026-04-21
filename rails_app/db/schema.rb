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

ActiveRecord::Schema[8.1].define(version: 2019_03_06_203527) do
  create_table "activities", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.string "event", null: false
    t.integer "item_id"
    t.string "item_type", null: false
    t.integer "transaction_id"
    t.integer "user_id"
  end

  create_table "bookmarks", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.string "document_id"
    t.string "document_type"
    t.text "tags"
    t.string "title"
    t.datetime "updated_at", precision: nil
    t.integer "user_id", null: false
    t.string "user_type"
    t.index ["user_id"], name: "index_bookmarks_on_user_id"
  end

  create_table "comments", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.text "comment"
    t.integer "commentable_id"
    t.string "commentable_type"
    t.datetime "created_at", precision: nil
    t.integer "created_by_id"
    t.boolean "deleted", default: false
    t.boolean "is_accepted", default: false
    t.boolean "is_correction", default: false
    t.boolean "public", default: true
    t.boolean "reviewed", default: false
    t.datetime "reviewed_at", precision: nil
    t.integer "reviewed_by_id"
    t.datetime "updated_at", precision: nil
    t.integer "updated_by_id"
    t.index ["created_by_id"], name: "index_comments_on_created_by_id"
    t.index ["reviewed_by_id"], name: "index_comments_on_reviewed_by_id"
    t.index ["updated_by_id"], name: "index_comments_on_updated_by_id"
  end

  create_table "delayed_jobs", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.integer "attempts", default: 0, null: false
    t.datetime "created_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "locked_at", precision: nil
    t.string "locked_by"
    t.integer "priority", default: 0, null: false
    t.string "queue"
    t.datetime "run_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "dericci_game_records", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.integer "dericci_game_id"
    t.integer "dericci_record_id"
  end

  create_table "dericci_games", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.integer "completed"
    t.datetime "created_at", precision: nil
    t.integer "created_by_id"
    t.integer "flagged", default: 0
    t.boolean "reviewed"
    t.integer "skipped"
    t.datetime "updated_at", precision: nil
    t.index ["created_by_id"], name: "index_dericci_games_on_created_by_id"
  end

  create_table "dericci_links", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.boolean "approved"
    t.datetime "created_at", precision: nil
    t.integer "created_by_id"
    t.integer "dericci_game_id"
    t.integer "dericci_record_id"
    t.integer "name_id"
    t.text "other_info"
    t.integer "reliability", default: 0
    t.datetime "updated_at", precision: nil
    t.integer "updated_by_id"
    t.index ["created_by_id"], name: "index_dericci_links_on_created_by_id"
    t.index ["updated_by_id"], name: "index_dericci_links_on_updated_by_id"
  end

  create_table "dericci_notes", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.string "cards"
    t.datetime "created_at", precision: nil, null: false
    t.string "link"
    t.string "name"
    t.string "senate_house"
    t.string "size"
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "dericci_record_flags", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "created_by_id"
    t.integer "dericci_record_id"
    t.text "reason"
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "dericci_records", id: :integer, charset: "utf8", force: :cascade do |t|
    t.integer "cards"
    t.integer "created_by_id"
    t.string "dates"
    t.string "name"
    t.text "other_info", size: :medium
    t.boolean "out_of_scope", default: false
    t.string "place"
    t.string "senate_house"
    t.string "size"
    t.integer "updated_by_id"
    t.string "url"
    t.integer "verified_id"
    t.index ["created_by_id"], name: "index_dericci_records_on_created_by_id"
    t.index ["updated_by_id"], name: "index_dericci_records_on_updated_by_id"
  end

  create_table "dericci_sales", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.string "cards"
    t.datetime "created_at", precision: nil, null: false
    t.string "link"
    t.string "name"
    t.string "senate_house"
    t.string "size"
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "downloads", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.integer "created_by_id"
    t.string "filename"
    t.integer "status", default: 0
    t.integer "user_id"
    t.index ["created_by_id"], name: "index_downloads_on_created_by_id"
    t.index ["user_id"], name: "index_downloads_on_user_id"
  end

  create_table "entries", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.string "alt_size"
    t.boolean "approved", default: false
    t.datetime "approved_at", precision: nil
    t.integer "approved_by_id"
    t.string "catalog_or_lot_number"
    t.boolean "confirmed", default: false
    t.datetime "created_at", precision: nil
    t.integer "created_by_id"
    t.boolean "deleted", default: false
    t.boolean "deprecated", default: false
    t.boolean "draft", default: false
    t.integer "folios"
    t.integer "height"
    t.integer "initials_decorated"
    t.integer "initials_historiated"
    t.integer "institution_id"
    t.string "manuscript_binding", limit: 1024
    t.string "manuscript_link", limit: 1024
    t.integer "miniatures_fullpage"
    t.integer "miniatures_large"
    t.integer "miniatures_small"
    t.integer "miniatures_unspec_size"
    t.integer "num_columns"
    t.integer "num_lines"
    t.text "other_info"
    t.integer "source_id"
    t.integer "superceded_by_id"
    t.integer "touch_count", default: 0, null: false
    t.string "transaction_type"
    t.boolean "unverified_legacy_record", default: false
    t.datetime "updated_at", precision: nil
    t.integer "updated_by_id"
    t.integer "width"
    t.index ["approved_by_id"], name: "index_entries_on_approved_by_id"
    t.index ["created_by_id"], name: "index_entries_on_created_by_id"
    t.index ["institution_id"], name: "index_entries_on_institution_id"
    t.index ["source_id"], name: "index_entries_on_source_id"
    t.index ["superceded_by_id"], name: "index_entries_on_superceded_by_id"
    t.index ["updated_by_id"], name: "index_entries_on_updated_by_id"
  end

  create_table "entry_artists", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.integer "artist_id"
    t.datetime "created_at", precision: nil
    t.integer "entry_id"
    t.string "observed_name"
    t.integer "order"
    t.string "role"
    t.boolean "supplied_by_data_entry", default: false
    t.boolean "uncertain_in_source", default: false
    t.datetime "updated_at", precision: nil
    t.index ["artist_id"], name: "index_entry_artists_on_artist_id"
    t.index ["entry_id"], name: "index_entry_artists_on_entry_id"
  end

  create_table "entry_authors", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.integer "author_id"
    t.datetime "created_at", precision: nil
    t.integer "entry_id"
    t.string "observed_name"
    t.integer "order"
    t.string "role"
    t.boolean "supplied_by_data_entry", default: false
    t.boolean "uncertain_in_source", default: false
    t.datetime "updated_at", precision: nil
    t.index ["author_id"], name: "index_entry_authors_on_author_id"
    t.index ["entry_id"], name: "index_entry_authors_on_entry_id"
  end

  create_table "entry_changes", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.datetime "change_date", precision: nil
    t.string "change_type"
    t.integer "changed_by_id"
    t.text "changed_from"
    t.text "changed_to"
    t.string "column"
    t.datetime "created_at", precision: nil
    t.integer "entry_id"
    t.datetime "updated_at", precision: nil
    t.index ["changed_by_id"], name: "index_entry_changes_on_changed_by_id"
    t.index ["entry_id"], name: "index_entry_changes_on_entry_id"
  end

  create_table "entry_comments", id: :integer, charset: "latin1", force: :cascade do |t|
    t.integer "comment_id"
    t.integer "entry_id"
    t.index ["comment_id"], name: "index_entry_comments_on_comment_id"
    t.index ["entry_id"], name: "index_entry_comments_on_entry_id"
  end

  create_table "entry_dates", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.string "date_normalized_end"
    t.string "date_normalized_start"
    t.integer "entry_id"
    t.string "observed_date"
    t.integer "order"
    t.boolean "supplied_by_data_entry", default: false
    t.boolean "uncertain_in_source", default: false
    t.datetime "updated_at", precision: nil
    t.index ["entry_id"], name: "index_entry_dates_on_entry_id"
  end

  create_table "entry_languages", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.integer "entry_id"
    t.integer "language_id"
    t.string "observed_name"
    t.integer "order"
    t.boolean "supplied_by_data_entry", default: false
    t.boolean "uncertain_in_source", default: false
    t.datetime "updated_at", precision: nil
    t.index ["entry_id"], name: "index_entry_languages_on_entry_id"
    t.index ["language_id"], name: "index_entry_languages_on_language_id"
  end

  create_table "entry_manuscript_activities", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.integer "activity_id"
    t.integer "entry_id"
    t.integer "manuscript_id"
    t.integer "transaction_id"
    t.index ["activity_id"], name: "index_entry_manuscript_activities_on_activity_id"
  end

  create_table "entry_manuscripts", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.integer "created_by_id"
    t.integer "entry_id"
    t.integer "manuscript_id"
    t.string "relation_type"
    t.boolean "reviewed", default: false
    t.datetime "reviewed_at", precision: nil
    t.integer "reviewed_by_id"
    t.datetime "updated_at", precision: nil
    t.integer "updated_by_id"
    t.index ["created_by_id"], name: "index_entry_manuscripts_on_created_by_id"
    t.index ["entry_id"], name: "index_entry_manuscripts_on_entry_id"
    t.index ["manuscript_id"], name: "index_entry_manuscripts_on_manuscript_id"
    t.index ["reviewed_by_id"], name: "index_entry_manuscripts_on_reviewed_by_id"
    t.index ["updated_by_id"], name: "index_entry_manuscripts_on_updated_by_id"
  end

  create_table "entry_materials", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.integer "entry_id"
    t.string "material"
    t.string "observed_name"
    t.integer "order"
    t.boolean "supplied_by_data_entry", default: false
    t.boolean "uncertain_in_source", default: false
    t.datetime "updated_at", precision: nil
    t.index ["entry_id"], name: "index_entry_materials_on_entry_id"
  end

  create_table "entry_places", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.integer "entry_id"
    t.string "observed_name"
    t.integer "order"
    t.integer "place_id"
    t.boolean "supplied_by_data_entry", default: false
    t.boolean "uncertain_in_source", default: false
    t.datetime "updated_at", precision: nil
    t.index ["entry_id"], name: "index_entry_places_on_entry_id"
    t.index ["place_id"], name: "index_entry_places_on_place_id"
  end

  create_table "entry_scribes", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.integer "entry_id"
    t.string "observed_name"
    t.integer "order"
    t.integer "scribe_id"
    t.boolean "supplied_by_data_entry", default: false
    t.boolean "uncertain_in_source", default: false
    t.datetime "updated_at", precision: nil
    t.index ["entry_id"], name: "index_entry_scribes_on_entry_id"
    t.index ["scribe_id"], name: "index_entry_scribes_on_scribe_id"
  end

  create_table "entry_titles", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.string "common_title", limit: 2048
    t.datetime "created_at", precision: nil
    t.integer "entry_id"
    t.integer "order"
    t.boolean "supplied_by_data_entry", default: false
    t.string "title", limit: 2048
    t.boolean "uncertain_in_source", default: false
    t.datetime "updated_at", precision: nil
    t.index ["entry_id"], name: "index_entry_titles_on_entry_id"
  end

  create_table "entry_uses", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.integer "entry_id"
    t.integer "order"
    t.datetime "updated_at", precision: nil
    t.string "use"
    t.index ["entry_id"], name: "index_entry_uses_on_entry_id"
  end

  create_table "friendly_id_slugs", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "scope", limit: 191
    t.string "slug", limit: 191, null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "group_records", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.boolean "editable", default: false
    t.integer "group_id"
    t.integer "record_id"
    t.string "record_type"
  end

  create_table "group_users", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.boolean "confirmed", default: false
    t.integer "created_by_id"
    t.integer "group_id"
    t.string "role", default: "Member"
    t.integer "user_id"
  end

  create_table "groups", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "created_by_id"
    t.text "description"
    t.text "name"
    t.boolean "public", default: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "updated_by_id"
  end

  create_table "jena_responses", id: :integer, charset: "latin1", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.text "message"
    t.integer "record_id"
    t.string "record_type"
    t.integer "status"
    t.integer "tries", default: 0
    t.datetime "updated_at", precision: nil, null: false
    t.index ["record_type", "record_id"], name: "index_jena_responses_on_record_type_and_record_id"
  end

  create_table "languages", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.integer "created_by_id"
    t.boolean "deleted", default: false
    t.integer "entries_count", default: 0, null: false
    t.string "name"
    t.boolean "problem", default: false
    t.boolean "reviewed", default: false
    t.datetime "reviewed_at", precision: nil
    t.integer "reviewed_by_id"
    t.datetime "updated_at", precision: nil
    t.integer "updated_by_id"
    t.index ["created_by_id"], name: "index_languages_on_created_by_id"
    t.index ["name"], name: "index_languages_on_name", unique: true
    t.index ["reviewed_by_id"], name: "index_languages_on_reviewed_by_id"
    t.index ["updated_by_id"], name: "index_languages_on_updated_by_id"
  end

  create_table "legacy_data_issues", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.string "explanation", limit: 1024
    t.string "issue_type"
    t.integer "record_id"
    t.string "table_name"
  end

  create_table "manuscript_comments", id: :integer, charset: "latin1", force: :cascade do |t|
    t.integer "comment_id"
    t.integer "manuscript_id"
    t.index ["comment_id"], name: "index_manuscript_comments_on_comment_id"
    t.index ["manuscript_id"], name: "index_manuscript_comments_on_manuscript_id"
  end

  create_table "manuscripts", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.integer "created_by_id"
    t.integer "entries_count", default: 0, null: false
    t.string "location"
    t.string "name"
    t.boolean "reviewed", default: false
    t.datetime "reviewed_at", precision: nil
    t.integer "reviewed_by_id"
    t.datetime "updated_at", precision: nil
    t.integer "updated_by_id"
    t.string "url"
    t.index ["created_by_id"], name: "index_manuscripts_on_created_by_id"
    t.index ["reviewed_by_id"], name: "index_manuscripts_on_reviewed_by_id"
    t.index ["updated_by_id"], name: "index_manuscripts_on_updated_by_id"
  end

  create_table "name_comments", id: :integer, charset: "latin1", force: :cascade do |t|
    t.integer "comment_id"
    t.integer "name_id"
    t.index ["comment_id"], name: "index_name_comments_on_comment_id"
    t.index ["name_id"], name: "index_name_comments_on_name_id"
  end

  create_table "name_places", id: :integer, charset: "latin1", force: :cascade do |t|
    t.integer "name_id"
    t.string "notafter"
    t.string "notbefore"
    t.integer "order"
    t.integer "place_id"
    t.index ["name_id"], name: "index_name_places_on_name_id"
    t.index ["place_id"], name: "index_name_places_on_place_id"
  end

  create_table "names", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.integer "artists_count", default: 0, null: false
    t.integer "associated_place_id"
    t.integer "authors_count", default: 0, null: false
    t.boolean "confirmed", default: false
    t.datetime "created_at", precision: nil
    t.integer "created_by_id"
    t.boolean "deleted", default: false
    t.string "enddate"
    t.integer "entry_id"
    t.boolean "is_artist", default: false
    t.boolean "is_author", default: false
    t.boolean "is_provenance_agent", default: false
    t.boolean "is_scribe", default: false
    t.string "name"
    t.text "other_info"
    t.boolean "problem", default: false
    t.integer "provenance_count", default: 0, null: false
    t.boolean "reviewed", default: false
    t.datetime "reviewed_at", precision: nil
    t.integer "reviewed_by_id"
    t.integer "sale_agents_count", default: 0, null: false
    t.integer "scribes_count", default: 0, null: false
    t.integer "source_agents_count", default: 0, null: false
    t.string "startdate"
    t.string "subtype"
    t.datetime "updated_at", precision: nil
    t.integer "updated_by_id"
    t.string "viaf_id"
    t.index ["created_by_id"], name: "index_names_on_created_by_id"
    t.index ["entry_id"], name: "index_names_on_entry_id"
    t.index ["is_artist"], name: "index_names_on_is_artist"
    t.index ["is_author"], name: "index_names_on_is_author"
    t.index ["is_provenance_agent"], name: "index_names_on_is_provenance_agent"
    t.index ["is_scribe"], name: "index_names_on_is_scribe"
    t.index ["name"], name: "index_names_on_name", unique: true
    t.index ["reviewed_by_id"], name: "index_names_on_reviewed_by_id"
    t.index ["updated_by_id"], name: "index_names_on_updated_by_id"
  end

  create_table "notification_settings", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.boolean "auto_watch", default: true
    t.datetime "created_at", precision: nil, null: false
    t.boolean "email_on_all_comment", default: false
    t.boolean "email_on_comment", default: true
    t.boolean "email_on_forum_post", default: true
    t.boolean "email_on_group", default: true
    t.boolean "email_on_message", default: true
    t.boolean "email_on_new_user", default: false
    t.boolean "email_on_reply", default: true
    t.boolean "email_on_update", default: true
    t.boolean "on_all_comment", default: true
    t.boolean "on_comment", default: true
    t.boolean "on_forum_post", default: true
    t.boolean "on_group", default: true
    t.boolean "on_message", default: true
    t.boolean "on_new_user", default: false
    t.boolean "on_reply", default: true
    t.boolean "on_update", default: true
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id"
  end

  create_table "notifications", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "category"
    t.datetime "created_at", precision: nil, null: false
    t.string "message"
    t.integer "notified_id"
    t.string "notified_type"
    t.string "title"
    t.datetime "updated_at", precision: nil, null: false
    t.string "url"
    t.integer "user_id"
  end

  create_table "pages", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.string "category", default: "upload"
    t.datetime "created_at", precision: nil, default: "2017-01-20 18:04:43"
    t.string "filename"
    t.string "name"
    t.datetime "updated_at", precision: nil, default: "2017-01-20 18:04:44"
    t.index ["filename"], name: "index_pages_on_filename"
    t.index ["name"], name: "index_pages_on_name"
  end

  create_table "places", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.string "authority_id"
    t.string "authority_source"
    t.datetime "created_at", precision: nil
    t.integer "created_by_id"
    t.boolean "deleted", default: false
    t.integer "entries_count", default: 0, null: false
    t.integer "entry_id"
    t.text "evidence"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.string "name"
    t.integer "parent_id"
    t.boolean "problem", default: false
    t.boolean "reviewed", default: false
    t.datetime "reviewed_at", precision: nil
    t.integer "reviewed_by_id"
    t.datetime "updated_at", precision: nil
    t.integer "updated_by_id"
    t.index ["created_by_id"], name: "index_places_on_created_by_id"
    t.index ["entry_id"], name: "index_places_on_entry_id"
    t.index ["name"], name: "index_places_on_name", unique: true
    t.index ["reviewed_by_id"], name: "index_places_on_reviewed_by_id"
    t.index ["updated_by_id"], name: "index_places_on_updated_by_id"
  end

  create_table "private_messages", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.integer "created_by_id"
    t.boolean "deleted", default: false
    t.text "message"
    t.integer "private_message_id"
    t.text "title"
    t.datetime "updated_at", precision: nil
    t.integer "updated_by_id"
    t.integer "user_id"
    t.index ["created_by_id"], name: "index_private_messages_on_created_by_id"
    t.index ["private_message_id"], name: "index_private_messages_on_private_message_id"
    t.index ["updated_by_id"], name: "index_private_messages_on_updated_by_id"
    t.index ["user_id"], name: "index_private_messages_on_user_id"
  end

  create_table "provenance", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.string "acquisition_method"
    t.string "associated_date"
    t.string "associated_date_normalized_end"
    t.string "associated_date_normalized_start"
    t.text "comment"
    t.datetime "created_at", precision: nil
    t.integer "created_by_id"
    t.boolean "direct_transfer", default: false
    t.string "end_date"
    t.string "end_date_normalized_end"
    t.string "end_date_normalized_start"
    t.integer "entry_id"
    t.string "observed_name"
    t.integer "order"
    t.integer "provenance_agent_id"
    t.string "start_date"
    t.string "start_date_normalized_end"
    t.string "start_date_normalized_start"
    t.boolean "supplied_by_data_entry", default: false
    t.boolean "uncertain_in_source", default: false
    t.datetime "updated_at", precision: nil
    t.integer "updated_by_id"
    t.index ["entry_id"], name: "index_provenance_on_entry_id"
    t.index ["provenance_agent_id"], name: "index_provenance_on_provenance_agent_id"
  end

  create_table "ratings", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "qualifier", default: "confirm"
    t.integer "ratable_id"
    t.string "ratable_type"
    t.text "reason"
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id"
    t.string "user_level"
  end

  create_table "replies", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.integer "comment_id"
    t.datetime "created_at", precision: nil, null: false
    t.integer "created_by_id"
    t.boolean "deleted", default: false
    t.text "reply"
    t.datetime "updated_at", precision: nil, null: false
    t.integer "updated_by_id"
    t.index ["comment_id"], name: "index_replies_on_comment_id"
    t.index ["created_by_id"], name: "index_replies_on_created_by_id"
    t.index ["updated_by_id"], name: "index_replies_on_updated_by_id"
  end

  create_table "sale_agents", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.integer "agent_id"
    t.datetime "created_at", precision: nil
    t.string "observed_name"
    t.string "role"
    t.integer "sale_id"
    t.boolean "supplied_by_data_entry", default: false
    t.boolean "uncertain_in_source", default: false
    t.datetime "updated_at", precision: nil
    t.index ["agent_id"], name: "index_sale_agents_on_agent_id"
    t.index ["observed_name"], name: "index_sale_agents_on_observed_name"
    t.index ["sale_id"], name: "index_sale_agents_on_sale_id"
  end

  create_table "sales", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.integer "created_by_id"
    t.string "currency"
    t.string "date"
    t.integer "entry_id"
    t.string "other_currency"
    t.decimal "price", precision: 20, scale: 2
    t.string "sold"
    t.datetime "updated_at", precision: nil
    t.integer "updated_by_id"
    t.index ["created_by_id"], name: "index_sales_on_created_by_id"
    t.index ["entry_id"], name: "index_sales_on_entry_id"
    t.index ["updated_by_id"], name: "index_sales_on_updated_by_id"
  end

  create_table "searches", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.text "query_params"
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.string "user_type"
    t.index ["user_id"], name: "index_searches_on_user_id"
  end

  create_table "sessions", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.text "data"
    t.string "session_id", null: false
    t.datetime "updated_at", precision: nil
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "source_agents", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.integer "agent_id"
    t.datetime "created_at", precision: nil
    t.string "observed_name"
    t.string "role"
    t.integer "source_id"
    t.datetime "updated_at", precision: nil
    t.index ["agent_id"], name: "index_source_agents_on_agent_id"
    t.index ["source_id"], name: "index_source_agents_on_source_id"
  end

  create_table "source_comments", id: :integer, charset: "latin1", force: :cascade do |t|
    t.integer "comment_id"
    t.integer "source_id"
    t.index ["comment_id"], name: "index_source_comments_on_comment_id"
    t.index ["source_id"], name: "index_source_comments_on_source_id"
  end

  create_table "source_types", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.string "display_name"
    t.boolean "entries_have_institution_field"
    t.string "entries_transaction_field"
    t.string "name"
  end

  create_table "sources", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.string "author"
    t.datetime "created_at", precision: nil
    t.integer "created_by_id"
    t.string "date"
    t.string "date_accessed"
    t.boolean "deleted"
    t.integer "entries_count", default: 0, null: false
    t.string "hidden"
    t.boolean "in_manuscript_table"
    t.boolean "legacy", default: false
    t.string "link", limit: 512
    t.string "location"
    t.string "location_institution"
    t.string "medium"
    t.text "other_info"
    t.boolean "problem", default: false
    t.boolean "reviewed", default: false
    t.datetime "reviewed_at", precision: nil
    t.integer "reviewed_by_id"
    t.integer "source_type_id"
    t.string "status"
    t.string "title", limit: 512
    t.datetime "updated_at", precision: nil
    t.integer "updated_by_id"
    t.string "whether_mss"
    t.index ["created_by_id"], name: "index_sources_on_created_by_id"
    t.index ["reviewed_by_id"], name: "index_sources_on_reviewed_by_id"
    t.index ["source_type_id"], name: "index_sources_on_source_type_id"
    t.index ["updated_by_id"], name: "index_sources_on_updated_by_id"
  end

  create_table "thredded_categories", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "description"
    t.integer "messageboard_id", null: false
    t.string "name", limit: 191, null: false
    t.string "slug", limit: 191, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["messageboard_id", "slug"], name: "index_thredded_categories_on_messageboard_id_and_slug", unique: true
    t.index ["messageboard_id"], name: "index_thredded_categories_on_messageboard_id"
    t.index ["name"], name: "thredded_categories_name_ci"
  end

  create_table "thredded_messageboard_groups", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "name"
    t.integer "position", null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "thredded_messageboard_notifications_for_followed_topics", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.boolean "enabled", default: true, null: false
    t.integer "messageboard_id", null: false
    t.string "notifier_key", limit: 90, null: false
    t.integer "user_id", null: false
    t.index ["user_id", "messageboard_id", "notifier_key"], name: "thredded_messageboard_notifications_for_followed_topics_unique", unique: true
  end

  create_table "thredded_messageboard_users", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.datetime "last_seen_at", precision: nil, null: false
    t.integer "thredded_messageboard_id", null: false
    t.integer "thredded_user_detail_id", null: false
    t.index ["thredded_messageboard_id", "last_seen_at"], name: "index_thredded_messageboard_users_for_recently_active"
    t.index ["thredded_messageboard_id", "thredded_user_detail_id"], name: "index_thredded_messageboard_users_primary"
    t.index ["thredded_user_detail_id"], name: "fk_rails_06e42c62f5"
  end

  create_table "thredded_messageboards", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.text "description"
    t.integer "last_topic_id"
    t.integer "messageboard_group_id"
    t.string "name", limit: 191, null: false
    t.integer "position", null: false
    t.integer "posts_count", default: 0
    t.string "slug", limit: 191
    t.integer "topics_count", default: 0
    t.datetime "updated_at", precision: nil, null: false
    t.index ["messageboard_group_id"], name: "index_thredded_messageboards_on_messageboard_group_id"
    t.index ["slug"], name: "index_thredded_messageboards_on_slug"
  end

  create_table "thredded_notifications_for_followed_topics", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.boolean "enabled", default: true, null: false
    t.string "notifier_key", limit: 90, null: false
    t.integer "user_id", null: false
    t.index ["user_id", "notifier_key"], name: "thredded_notifications_for_followed_topics_unique", unique: true
  end

  create_table "thredded_notifications_for_private_topics", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.boolean "enabled", default: true, null: false
    t.string "notifier_key", limit: 90, null: false
    t.integer "user_id", null: false
    t.index ["user_id", "notifier_key"], name: "thredded_notifications_for_private_topics_unique", unique: true
  end

  create_table "thredded_post_moderation_records", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "messageboard_id"
    t.integer "moderation_state", null: false
    t.integer "moderator_id"
    t.text "post_content"
    t.integer "post_id"
    t.integer "post_user_id"
    t.text "post_user_name"
    t.integer "previous_moderation_state", null: false
    t.index ["messageboard_id", "created_at"], name: "index_thredded_moderation_records_for_display"
  end

  create_table "thredded_post_notifications", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "email", limit: 191, null: false
    t.integer "post_id", null: false
    t.string "post_type", limit: 191
    t.datetime "updated_at", precision: nil, null: false
    t.index ["post_id", "post_type"], name: "index_thredded_post_notifications_on_post"
  end

  create_table "thredded_posts", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", precision: nil, null: false
    t.string "ip"
    t.integer "messageboard_id", null: false
    t.integer "moderation_state", null: false
    t.integer "postable_id", null: false
    t.string "source", default: "web"
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id"
    t.index ["content"], name: "thredded_posts_content_fts", type: :fulltext
    t.index ["messageboard_id"], name: "index_thredded_posts_on_messageboard_id"
    t.index ["moderation_state", "updated_at"], name: "index_thredded_posts_for_display"
    t.index ["postable_id"], name: "index_thredded_posts_on_postable_id_and_postable_type"
    t.index ["user_id"], name: "index_thredded_posts_on_user_id"
  end

  create_table "thredded_private_posts", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", precision: nil, null: false
    t.string "ip"
    t.integer "postable_id", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id"
  end

  create_table "thredded_private_topics", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "hash_id", limit: 191, null: false
    t.datetime "last_post_at", precision: nil
    t.integer "last_user_id"
    t.integer "posts_count", default: 0
    t.string "slug", limit: 191, null: false
    t.string "title", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id"
    t.index ["hash_id"], name: "index_thredded_private_topics_on_hash_id"
    t.index ["slug"], name: "index_thredded_private_topics_on_slug"
  end

  create_table "thredded_private_users", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "private_topic_id"
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id"
    t.index ["private_topic_id"], name: "index_thredded_private_users_on_private_topic_id"
    t.index ["user_id"], name: "index_thredded_private_users_on_user_id"
  end

  create_table "thredded_topic_categories", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.integer "category_id", null: false
    t.integer "topic_id", null: false
    t.index ["category_id"], name: "index_thredded_topic_categories_on_category_id"
    t.index ["topic_id"], name: "index_thredded_topic_categories_on_topic_id"
  end

  create_table "thredded_topics", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "hash_id", limit: 191, null: false
    t.datetime "last_post_at", precision: nil
    t.integer "last_user_id"
    t.boolean "locked", default: false, null: false
    t.integer "messageboard_id", null: false
    t.integer "moderation_state", null: false
    t.integer "posts_count", default: 0, null: false
    t.string "slug", limit: 191, null: false
    t.boolean "sticky", default: false, null: false
    t.string "title", null: false
    t.string "type", limit: 191
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id"
    t.index ["hash_id"], name: "index_thredded_topics_on_hash_id"
    t.index ["messageboard_id", "slug"], name: "index_thredded_topics_on_messageboard_id_and_slug", unique: true
    t.index ["messageboard_id"], name: "index_thredded_topics_on_messageboard_id"
    t.index ["moderation_state", "sticky", "updated_at"], name: "index_thredded_topics_for_display"
    t.index ["title"], name: "thredded_topics_title_fts", type: :fulltext
    t.index ["user_id"], name: "index_thredded_topics_on_user_id"
  end

  create_table "thredded_user_details", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "last_seen_at", precision: nil
    t.datetime "latest_activity_at", precision: nil
    t.integer "moderation_state", default: 0, null: false
    t.datetime "moderation_state_changed_at", precision: nil
    t.integer "posts_count", default: 0
    t.integer "topics_count", default: 0
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id", null: false
    t.index ["latest_activity_at"], name: "index_thredded_user_details_on_latest_activity_at"
    t.index ["moderation_state", "moderation_state_changed_at"], name: "index_thredded_user_details_for_moderations"
    t.index ["user_id"], name: "index_thredded_user_details_on_user_id"
  end

  create_table "thredded_user_messageboard_preferences", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.boolean "follow_topics_on_mention", default: true, null: false
    t.integer "messageboard_id", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id", null: false
    t.index ["user_id", "messageboard_id"], name: "thredded_user_messageboard_preferences_user_id_messageboard_id", unique: true
  end

  create_table "thredded_user_preferences", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.boolean "follow_topics_on_mention", default: true, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_thredded_user_preferences_on_user_id"
  end

  create_table "thredded_user_private_topic_read_states", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.integer "page", default: 1, null: false
    t.integer "postable_id", null: false
    t.datetime "read_at", precision: nil, null: false
    t.integer "user_id", null: false
    t.index ["user_id", "postable_id"], name: "thredded_user_private_topic_read_states_user_postable", unique: true
  end

  create_table "thredded_user_topic_follows", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "reason", limit: 1
    t.integer "topic_id", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "topic_id"], name: "thredded_user_topic_follows_user_topic", unique: true
  end

  create_table "thredded_user_topic_read_states", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.integer "page", default: 1, null: false
    t.integer "postable_id", null: false
    t.datetime "read_at", precision: nil, null: false
    t.integer "user_id", null: false
    t.index ["user_id", "postable_id"], name: "thredded_user_topic_read_states_user_postable", unique: true
  end

  create_table "user_messages", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.boolean "deleted", default: false
    t.string "method"
    t.integer "private_message_id", null: false
    t.boolean "unread", default: true
    t.integer "user_id", null: false
  end

  create_table "users", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.boolean "active", default: true
    t.boolean "active_survey", default: true
    t.boolean "backup", default: true
    t.text "bio"
    t.integer "bookmark_tracker", default: 0
    t.datetime "created_at", precision: nil
    t.integer "created_by_id"
    t.datetime "current_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.boolean "email_is_public", default: false
    t.string "encrypted_password", default: "", null: false
    t.string "fullname"
    t.boolean "guest", default: false
    t.string "institutional_affiliation"
    t.datetime "last_sign_in_at", precision: nil
    t.string "last_sign_in_ip"
    t.datetime "remember_created_at", precision: nil
    t.datetime "reset_password_sent_at", precision: nil
    t.string "reset_password_token"
    t.boolean "reviewed", default: false
    t.datetime "reviewed_at", precision: nil
    t.integer "reviewed_by_id"
    t.string "role"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "updated_at", precision: nil
    t.integer "updated_by_id"
    t.string "username"
    t.index ["created_by_id"], name: "index_users_on_created_by_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["reviewed_by_id"], name: "index_users_on_reviewed_by_id"
    t.index ["updated_by_id"], name: "index_users_on_updated_by_id"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "version_associations", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.integer "foreign_key_id"
    t.string "foreign_key_name", null: false
    t.integer "version_id"
    t.index ["foreign_key_name", "foreign_key_id"], name: "index_version_associations_on_foreign_key"
    t.index ["version_id"], name: "index_version_associations_on_version_id"
  end

  create_table "versions", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.string "event", null: false
    t.integer "item_id", null: false
    t.string "item_type", null: false
    t.text "object"
    t.text "object_changes"
    t.integer "transaction_id"
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
    t.index ["transaction_id"], name: "index_versions_on_transaction_id"
  end

  create_table "watches", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "watched_id"
    t.string "watched_type"
  end

  add_foreign_key "comments", "users", column: "created_by_id"
  add_foreign_key "comments", "users", column: "reviewed_by_id"
  add_foreign_key "comments", "users", column: "updated_by_id"
  add_foreign_key "entries", "entries", column: "superceded_by_id"
  add_foreign_key "entries", "names", column: "institution_id"
  add_foreign_key "entries", "sources"
  add_foreign_key "entries", "users", column: "approved_by_id"
  add_foreign_key "entries", "users", column: "created_by_id"
  add_foreign_key "entries", "users", column: "updated_by_id"
  add_foreign_key "entry_artists", "entries", on_delete: :cascade
  add_foreign_key "entry_artists", "names", column: "artist_id"
  add_foreign_key "entry_authors", "entries", on_delete: :cascade
  add_foreign_key "entry_authors", "names", column: "author_id"
  add_foreign_key "entry_changes", "entries", on_delete: :cascade
  add_foreign_key "entry_changes", "users", column: "changed_by_id"
  add_foreign_key "entry_comments", "comments"
  add_foreign_key "entry_comments", "entries"
  add_foreign_key "entry_dates", "entries", on_delete: :cascade
  add_foreign_key "entry_languages", "entries", on_delete: :cascade
  add_foreign_key "entry_languages", "languages"
  add_foreign_key "entry_manuscript_activities", "activities"
  add_foreign_key "entry_manuscripts", "entries", on_delete: :cascade
  add_foreign_key "entry_manuscripts", "manuscripts"
  add_foreign_key "entry_manuscripts", "users", column: "created_by_id"
  add_foreign_key "entry_manuscripts", "users", column: "reviewed_by_id"
  add_foreign_key "entry_manuscripts", "users", column: "updated_by_id"
  add_foreign_key "entry_materials", "entries", on_delete: :cascade
  add_foreign_key "entry_places", "entries", on_delete: :cascade
  add_foreign_key "entry_places", "places"
  add_foreign_key "entry_scribes", "entries", on_delete: :cascade
  add_foreign_key "entry_scribes", "names", column: "scribe_id"
  add_foreign_key "entry_titles", "entries", on_delete: :cascade
  add_foreign_key "entry_uses", "entries", on_delete: :cascade
  add_foreign_key "languages", "users", column: "created_by_id"
  add_foreign_key "languages", "users", column: "reviewed_by_id"
  add_foreign_key "languages", "users", column: "updated_by_id"
  add_foreign_key "manuscript_comments", "comments"
  add_foreign_key "manuscript_comments", "manuscripts"
  add_foreign_key "manuscripts", "users", column: "created_by_id"
  add_foreign_key "manuscripts", "users", column: "reviewed_by_id"
  add_foreign_key "manuscripts", "users", column: "updated_by_id"
  add_foreign_key "name_comments", "comments"
  add_foreign_key "name_comments", "names"
  add_foreign_key "names", "entries", on_delete: :cascade
  add_foreign_key "names", "users", column: "created_by_id"
  add_foreign_key "names", "users", column: "reviewed_by_id"
  add_foreign_key "names", "users", column: "updated_by_id"
  add_foreign_key "places", "entries", on_delete: :cascade
  add_foreign_key "places", "users", column: "created_by_id"
  add_foreign_key "places", "users", column: "reviewed_by_id"
  add_foreign_key "places", "users", column: "updated_by_id"
  add_foreign_key "private_messages", "entries", column: "user_id"
  add_foreign_key "private_messages", "private_messages"
  add_foreign_key "private_messages", "users", column: "created_by_id"
  add_foreign_key "private_messages", "users", column: "updated_by_id"
  add_foreign_key "provenance", "names", column: "provenance_agent_id"
  add_foreign_key "replies", "comments"
  add_foreign_key "sale_agents", "names", column: "agent_id"
  add_foreign_key "sale_agents", "sales", on_delete: :cascade
  add_foreign_key "sales", "entries", on_delete: :cascade
  add_foreign_key "sales", "users", column: "created_by_id"
  add_foreign_key "sales", "users", column: "updated_by_id"
  add_foreign_key "source_agents", "names", column: "agent_id"
  add_foreign_key "source_agents", "sources", on_delete: :cascade
  add_foreign_key "source_comments", "comments"
  add_foreign_key "source_comments", "sources"
  add_foreign_key "sources", "source_types"
  add_foreign_key "sources", "users", column: "created_by_id"
  add_foreign_key "sources", "users", column: "reviewed_by_id"
  add_foreign_key "sources", "users", column: "updated_by_id"
  add_foreign_key "thredded_messageboard_users", "thredded_messageboards"
  add_foreign_key "thredded_messageboard_users", "thredded_user_details"
  add_foreign_key "users", "users", column: "created_by_id"
  add_foreign_key "users", "users", column: "reviewed_by_id"
  add_foreign_key "users", "users", column: "updated_by_id"
end
