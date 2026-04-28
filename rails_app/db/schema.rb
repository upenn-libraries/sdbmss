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

ActiveRecord::Schema.define(version: 2019_03_06_203527) do

  create_table "activities", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id"
    t.string "event", null: false
    t.integer "user_id"
    t.datetime "created_at"
    t.integer "transaction_id"
  end

  create_table "bookmarks", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "user_type"
    t.string "document_id"
    t.string "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "document_type"
    t.text "tags"
    t.index ["user_id"], name: "index_bookmarks_on_user_id"
  end

  create_table "comments", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.text "comment"
    t.boolean "public", default: true
    t.boolean "is_correction", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "reviewed", default: false
    t.datetime "reviewed_at"
    t.boolean "deleted", default: false
    t.integer "created_by_id"
    t.integer "updated_by_id"
    t.integer "reviewed_by_id"
    t.boolean "is_accepted", default: false
    t.integer "commentable_id"
    t.string "commentable_type"
    t.index ["created_by_id"], name: "index_comments_on_created_by_id"
    t.index ["reviewed_by_id"], name: "index_comments_on_reviewed_by_id"
    t.index ["updated_by_id"], name: "index_comments_on_updated_by_id"
  end

  create_table "delayed_jobs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "dericci_game_records", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "dericci_game_id"
    t.integer "dericci_record_id"
  end

  create_table "dericci_games", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "created_by_id"
    t.boolean "reviewed"
    t.integer "skipped"
    t.integer "completed"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "flagged", default: 0
    t.index ["created_by_id"], name: "index_dericci_games_on_created_by_id"
  end

  create_table "dericci_links", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "name_id"
    t.integer "dericci_record_id"
    t.datetime "created_at"
    t.integer "created_by_id"
    t.datetime "updated_at"
    t.integer "updated_by_id"
    t.boolean "approved"
    t.integer "dericci_game_id"
    t.text "other_info"
    t.integer "reliability", default: 0
    t.index ["created_by_id"], name: "index_dericci_links_on_created_by_id"
    t.index ["updated_by_id"], name: "index_dericci_links_on_updated_by_id"
  end

  create_table "dericci_notes", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.string "cards"
    t.string "size"
    t.string "senate_house"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "link"
  end

  create_table "dericci_record_flags", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "dericci_record_id"
    t.text "reason"
    t.integer "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "dericci_records", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "dates"
    t.string "place"
    t.string "url"
    t.integer "cards"
    t.string "size"
    t.text "other_info", limit: 16777215
    t.string "senate_house"
    t.integer "created_by_id"
    t.integer "verified_id"
    t.integer "updated_by_id"
    t.boolean "out_of_scope", default: false
    t.index ["created_by_id"], name: "index_dericci_records_on_created_by_id"
    t.index ["updated_by_id"], name: "index_dericci_records_on_updated_by_id"
  end

  create_table "dericci_sales", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.string "cards"
    t.string "size"
    t.string "senate_house"
    t.string "link"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "downloads", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "filename"
    t.integer "status", default: 0
    t.integer "user_id"
    t.integer "created_by_id"
    t.datetime "created_at"
    t.index ["created_by_id"], name: "index_downloads_on_created_by_id"
    t.index ["user_id"], name: "index_downloads_on_user_id"
  end

  create_table "entries", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "source_id"
    t.string "catalog_or_lot_number"
    t.integer "folios"
    t.integer "num_columns"
    t.integer "num_lines"
    t.integer "height"
    t.integer "width"
    t.string "alt_size"
    t.string "manuscript_binding", limit: 1024
    t.text "other_info"
    t.string "manuscript_link", limit: 1024
    t.integer "miniatures_fullpage"
    t.integer "miniatures_large"
    t.integer "miniatures_small"
    t.integer "miniatures_unspec_size"
    t.integer "initials_historiated"
    t.integer "initials_decorated"
    t.boolean "approved", default: false
    t.boolean "deleted", default: false
    t.datetime "created_at"
    t.integer "created_by_id"
    t.datetime "updated_at"
    t.integer "updated_by_id"
    t.integer "institution_id"
    t.string "transaction_type"
    t.integer "approved_by_id"
    t.datetime "approved_at"
    t.integer "touch_count", default: 0, null: false
    t.boolean "deprecated", default: false
    t.integer "superceded_by_id"
    t.boolean "unverified_legacy_record", default: false
    t.boolean "confirmed", default: false
    t.boolean "draft", default: false
    t.index ["approved_by_id"], name: "index_entries_on_approved_by_id"
    t.index ["created_by_id"], name: "index_entries_on_created_by_id"
    t.index ["institution_id"], name: "index_entries_on_institution_id"
    t.index ["source_id"], name: "index_entries_on_source_id"
    t.index ["superceded_by_id"], name: "index_entries_on_superceded_by_id"
    t.index ["updated_by_id"], name: "index_entries_on_updated_by_id"
  end

  create_table "entry_artists", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "entry_id"
    t.integer "artist_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "uncertain_in_source", default: false
    t.boolean "supplied_by_data_entry", default: false
    t.string "observed_name"
    t.integer "order"
    t.string "role"
    t.index ["artist_id"], name: "index_entry_artists_on_artist_id"
    t.index ["entry_id"], name: "index_entry_artists_on_entry_id"
  end

  create_table "entry_authors", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "entry_id"
    t.integer "author_id"
    t.string "observed_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "role"
    t.boolean "uncertain_in_source", default: false
    t.boolean "supplied_by_data_entry", default: false
    t.integer "order"
    t.index ["author_id"], name: "index_entry_authors_on_author_id"
    t.index ["entry_id"], name: "index_entry_authors_on_entry_id"
  end

  create_table "entry_changes", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "entry_id"
    t.string "column"
    t.text "changed_from"
    t.text "changed_to"
    t.string "change_type"
    t.datetime "change_date"
    t.integer "changed_by_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["changed_by_id"], name: "index_entry_changes_on_changed_by_id"
    t.index ["entry_id"], name: "index_entry_changes_on_entry_id"
  end

  create_table "entry_comments", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.integer "entry_id"
    t.integer "comment_id"
    t.index ["comment_id"], name: "index_entry_comments_on_comment_id"
    t.index ["entry_id"], name: "index_entry_comments_on_entry_id"
  end

  create_table "entry_dates", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "entry_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "observed_date"
    t.string "date_normalized_start"
    t.string "date_normalized_end"
    t.boolean "uncertain_in_source", default: false
    t.boolean "supplied_by_data_entry", default: false
    t.integer "order"
    t.index ["entry_id"], name: "index_entry_dates_on_entry_id"
  end

  create_table "entry_languages", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "entry_id"
    t.integer "language_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "uncertain_in_source", default: false
    t.boolean "supplied_by_data_entry", default: false
    t.integer "order"
    t.string "observed_name"
    t.index ["entry_id"], name: "index_entry_languages_on_entry_id"
    t.index ["language_id"], name: "index_entry_languages_on_language_id"
  end

  create_table "entry_manuscript_activities", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "activity_id"
    t.integer "entry_id"
    t.integer "manuscript_id"
    t.integer "transaction_id"
    t.index ["activity_id"], name: "index_entry_manuscript_activities_on_activity_id"
  end

  create_table "entry_manuscripts", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "entry_id"
    t.integer "manuscript_id"
    t.string "relation_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "reviewed", default: false
    t.integer "reviewed_by_id"
    t.datetime "reviewed_at"
    t.integer "created_by_id"
    t.integer "updated_by_id"
    t.index ["created_by_id"], name: "index_entry_manuscripts_on_created_by_id"
    t.index ["entry_id"], name: "index_entry_manuscripts_on_entry_id"
    t.index ["manuscript_id"], name: "index_entry_manuscripts_on_manuscript_id"
    t.index ["reviewed_by_id"], name: "index_entry_manuscripts_on_reviewed_by_id"
    t.index ["updated_by_id"], name: "index_entry_manuscripts_on_updated_by_id"
  end

  create_table "entry_materials", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "entry_id"
    t.string "material"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "uncertain_in_source", default: false
    t.boolean "supplied_by_data_entry", default: false
    t.integer "order"
    t.string "observed_name"
    t.index ["entry_id"], name: "index_entry_materials_on_entry_id"
  end

  create_table "entry_places", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "entry_id"
    t.integer "place_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "uncertain_in_source", default: false
    t.boolean "supplied_by_data_entry", default: false
    t.string "observed_name"
    t.integer "order"
    t.index ["entry_id"], name: "index_entry_places_on_entry_id"
    t.index ["place_id"], name: "index_entry_places_on_place_id"
  end

  create_table "entry_scribes", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "entry_id"
    t.integer "scribe_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "uncertain_in_source", default: false
    t.boolean "supplied_by_data_entry", default: false
    t.string "observed_name"
    t.integer "order"
    t.index ["entry_id"], name: "index_entry_scribes_on_entry_id"
    t.index ["scribe_id"], name: "index_entry_scribes_on_scribe_id"
  end

  create_table "entry_titles", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "entry_id"
    t.string "title", limit: 2048
    t.string "common_title", limit: 2048
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "uncertain_in_source", default: false
    t.boolean "supplied_by_data_entry", default: false
    t.integer "order"
    t.index ["entry_id"], name: "index_entry_titles_on_entry_id"
  end

  create_table "entry_uses", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "entry_id"
    t.string "use"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "order"
    t.index ["entry_id"], name: "index_entry_uses_on_entry_id"
  end

  create_table "friendly_id_slugs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "slug", limit: 191, null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope", limit: 191
    t.datetime "created_at", null: false
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "group_records", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "record_id"
    t.string "record_type"
    t.integer "group_id"
    t.boolean "editable", default: false
  end

  create_table "group_users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "group_id"
    t.integer "user_id"
    t.string "role", default: "Member"
    t.boolean "confirmed", default: false
    t.integer "created_by_id"
  end

  create_table "groups", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.text "name"
    t.boolean "public", default: false
    t.integer "created_by_id"
    t.integer "updated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
  end

  create_table "jena_responses", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.text "message"
    t.integer "status"
    t.integer "record_id"
    t.string "record_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tries", default: 0
    t.index ["record_type", "record_id"], name: "index_jena_responses_on_record_type_and_record_id"
  end

  create_table "languages", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.integer "created_by_id"
    t.datetime "updated_at"
    t.integer "updated_by_id"
    t.integer "entries_count", default: 0, null: false
    t.boolean "deleted", default: false
    t.boolean "reviewed", default: false
    t.integer "reviewed_by_id"
    t.datetime "reviewed_at"
    t.boolean "problem", default: false
    t.index ["created_by_id"], name: "index_languages_on_created_by_id"
    t.index ["name"], name: "index_languages_on_name", unique: true
    t.index ["reviewed_by_id"], name: "index_languages_on_reviewed_by_id"
    t.index ["updated_by_id"], name: "index_languages_on_updated_by_id"
  end

  create_table "legacy_data_issues", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "table_name"
    t.integer "record_id"
    t.string "issue_type"
    t.string "explanation", limit: 1024
  end

  create_table "manuscript_comments", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.integer "manuscript_id"
    t.integer "comment_id"
    t.index ["comment_id"], name: "index_manuscript_comments_on_comment_id"
    t.index ["manuscript_id"], name: "index_manuscript_comments_on_manuscript_id"
  end

  create_table "manuscripts", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "created_by_id"
    t.integer "updated_by_id"
    t.string "name"
    t.integer "entries_count", default: 0, null: false
    t.string "location"
    t.boolean "reviewed", default: false
    t.integer "reviewed_by_id"
    t.datetime "reviewed_at"
    t.string "url"
    t.index ["created_by_id"], name: "index_manuscripts_on_created_by_id"
    t.index ["reviewed_by_id"], name: "index_manuscripts_on_reviewed_by_id"
    t.index ["updated_by_id"], name: "index_manuscripts_on_updated_by_id"
  end

  create_table "name_comments", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.integer "name_id"
    t.integer "comment_id"
    t.index ["comment_id"], name: "index_name_comments_on_comment_id"
    t.index ["name_id"], name: "index_name_comments_on_name_id"
  end

  create_table "name_places", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.integer "name_id"
    t.integer "place_id"
    t.string "notbefore"
    t.string "notafter"
    t.integer "order"
    t.index ["name_id"], name: "index_name_places_on_name_id"
    t.index ["place_id"], name: "index_name_places_on_place_id"
  end

  create_table "names", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.integer "entry_id"
    t.string "viaf_id"
    t.boolean "is_artist", default: false
    t.boolean "is_author", default: false
    t.boolean "is_scribe", default: false
    t.boolean "is_provenance_agent", default: false
    t.datetime "created_at"
    t.integer "created_by_id"
    t.datetime "updated_at"
    t.integer "updated_by_id"
    t.integer "authors_count", default: 0, null: false
    t.integer "artists_count", default: 0, null: false
    t.integer "scribes_count", default: 0, null: false
    t.integer "source_agents_count", default: 0, null: false
    t.integer "sale_agents_count", default: 0, null: false
    t.boolean "deleted", default: false
    t.text "other_info"
    t.boolean "reviewed", default: false
    t.integer "reviewed_by_id"
    t.datetime "reviewed_at"
    t.integer "provenance_count", default: 0, null: false
    t.boolean "confirmed", default: false
    t.boolean "problem", default: false
    t.string "subtype"
    t.integer "associated_place_id"
    t.string "startdate"
    t.string "enddate"
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

  create_table "notification_settings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.boolean "on_update", default: true
    t.boolean "on_comment", default: true
    t.boolean "on_reply", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "on_message", default: true
    t.boolean "email_on_message", default: true
    t.boolean "email_on_comment", default: true
    t.boolean "email_on_reply", default: true
    t.boolean "email_on_update", default: true
    t.boolean "on_new_user", default: false
    t.boolean "email_on_new_user", default: false
    t.boolean "on_group", default: true
    t.boolean "email_on_group", default: true
    t.boolean "on_all_comment", default: true
    t.boolean "email_on_all_comment", default: false
    t.boolean "auto_watch", default: true
    t.boolean "on_forum_post", default: true
    t.boolean "email_on_forum_post", default: true
  end

  create_table "notifications", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "message"
    t.string "category"
    t.boolean "active", default: true
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.string "title"
    t.integer "notified_id"
    t.string "notified_type"
  end

  create_table "pages", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "filename"
    t.string "name"
    t.string "category", default: "upload"
    t.datetime "created_at", default: "2017-01-20 18:04:43"
    t.datetime "updated_at", default: "2017-01-20 18:04:44"
    t.index ["filename"], name: "index_pages_on_filename"
    t.index ["name"], name: "index_pages_on_name"
  end

  create_table "places", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.integer "entry_id"
    t.datetime "created_at"
    t.integer "created_by_id"
    t.datetime "updated_at"
    t.integer "updated_by_id"
    t.integer "entries_count", default: 0, null: false
    t.boolean "deleted", default: false
    t.boolean "reviewed", default: false
    t.integer "reviewed_by_id"
    t.datetime "reviewed_at"
    t.boolean "problem", default: false
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.integer "parent_id"
    t.string "authority_id"
    t.string "authority_source"
    t.text "evidence"
    t.index ["created_by_id"], name: "index_places_on_created_by_id"
    t.index ["entry_id"], name: "index_places_on_entry_id"
    t.index ["name"], name: "index_places_on_name", unique: true
    t.index ["reviewed_by_id"], name: "index_places_on_reviewed_by_id"
    t.index ["updated_by_id"], name: "index_places_on_updated_by_id"
  end

  create_table "private_messages", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.text "message"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "deleted", default: false
    t.integer "created_by_id"
    t.integer "updated_by_id"
    t.integer "user_id"
    t.integer "private_message_id"
    t.text "title"
    t.index ["created_by_id"], name: "index_private_messages_on_created_by_id"
    t.index ["private_message_id"], name: "index_private_messages_on_private_message_id"
    t.index ["updated_by_id"], name: "index_private_messages_on_updated_by_id"
    t.index ["user_id"], name: "index_private_messages_on_user_id"
  end

  create_table "provenance", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "entry_id"
    t.integer "order"
    t.string "observed_name"
    t.integer "provenance_agent_id"
    t.string "acquisition_method"
    t.boolean "direct_transfer", default: false
    t.datetime "created_at"
    t.integer "created_by_id"
    t.datetime "updated_at"
    t.integer "updated_by_id"
    t.string "start_date"
    t.string "start_date_normalized_start"
    t.string "start_date_normalized_end"
    t.string "end_date"
    t.string "end_date_normalized_start"
    t.string "end_date_normalized_end"
    t.text "comment"
    t.boolean "uncertain_in_source", default: false
    t.boolean "supplied_by_data_entry", default: false
    t.string "associated_date"
    t.string "associated_date_normalized_start"
    t.string "associated_date_normalized_end"
    t.index ["entry_id"], name: "index_provenance_on_entry_id"
    t.index ["provenance_agent_id"], name: "index_provenance_on_provenance_agent_id"
  end

  create_table "ratings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "ratable_id"
    t.string "ratable_type"
    t.string "user_level"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "qualifier", default: "confirm"
    t.text "reason"
  end

  create_table "replies", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.text "reply"
    t.integer "comment_id"
    t.integer "created_by_id"
    t.integer "updated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "deleted", default: false
    t.index ["comment_id"], name: "index_replies_on_comment_id"
    t.index ["created_by_id"], name: "index_replies_on_created_by_id"
    t.index ["updated_by_id"], name: "index_replies_on_updated_by_id"
  end

  create_table "sale_agents", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "sale_id"
    t.string "observed_name"
    t.integer "agent_id"
    t.string "role"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "uncertain_in_source", default: false
    t.boolean "supplied_by_data_entry", default: false
    t.index ["agent_id"], name: "index_sale_agents_on_agent_id"
    t.index ["observed_name"], name: "index_sale_agents_on_observed_name"
    t.index ["sale_id"], name: "index_sale_agents_on_sale_id"
  end

  create_table "sales", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "entry_id"
    t.string "date"
    t.decimal "price", precision: 20, scale: 2
    t.string "currency"
    t.string "other_currency"
    t.string "sold"
    t.datetime "created_at"
    t.integer "created_by_id"
    t.datetime "updated_at"
    t.integer "updated_by_id"
    t.index ["created_by_id"], name: "index_sales_on_created_by_id"
    t.index ["entry_id"], name: "index_sales_on_entry_id"
    t.index ["updated_by_id"], name: "index_sales_on_updated_by_id"
  end

  create_table "searches", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.text "query_params"
    t.integer "user_id"
    t.string "user_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["user_id"], name: "index_searches_on_user_id"
  end

  create_table "sessions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "source_agents", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "source_id"
    t.integer "agent_id"
    t.string "role"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "observed_name"
    t.index ["agent_id"], name: "index_source_agents_on_agent_id"
    t.index ["source_id"], name: "index_source_agents_on_source_id"
  end

  create_table "source_comments", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.integer "source_id"
    t.integer "comment_id"
    t.index ["comment_id"], name: "index_source_comments_on_comment_id"
    t.index ["source_id"], name: "index_source_comments_on_source_id"
  end

  create_table "source_types", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.string "display_name"
    t.string "entries_transaction_field"
    t.boolean "entries_have_institution_field"
  end

  create_table "sources", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "date"
    t.string "title", limit: 512
    t.string "author"
    t.string "whether_mss"
    t.string "link", limit: 512
    t.boolean "in_manuscript_table"
    t.boolean "deleted"
    t.text "other_info"
    t.string "status"
    t.string "hidden"
    t.datetime "created_at"
    t.integer "created_by_id"
    t.datetime "updated_at"
    t.integer "updated_by_id"
    t.integer "entries_count", default: 0, null: false
    t.string "location_institution"
    t.string "location"
    t.string "medium"
    t.string "date_accessed"
    t.integer "source_type_id"
    t.boolean "reviewed", default: false
    t.integer "reviewed_by_id"
    t.datetime "reviewed_at"
    t.boolean "legacy", default: false
    t.boolean "problem", default: false
    t.index ["created_by_id"], name: "index_sources_on_created_by_id"
    t.index ["reviewed_by_id"], name: "index_sources_on_reviewed_by_id"
    t.index ["source_type_id"], name: "index_sources_on_source_type_id"
    t.index ["updated_by_id"], name: "index_sources_on_updated_by_id"
  end

  create_table "thredded_categories", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "messageboard_id", null: false
    t.text "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "slug", null: false
    t.index ["messageboard_id", "slug"], name: "index_thredded_categories_on_messageboard_id_and_slug", unique: true, length: { slug: 191 }
    t.index ["messageboard_id"], name: "index_thredded_categories_on_messageboard_id"
    t.index ["name"], name: "thredded_categories_name_ci", length: 191
  end

  create_table "thredded_messageboard_groups", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "thredded_messageboard_notifications_for_followed_topics", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "messageboard_id", null: false
    t.string "notifier_key", limit: 90, null: false
    t.boolean "enabled", default: true, null: false
    t.index ["user_id", "messageboard_id", "notifier_key"], name: "thredded_messageboard_notifications_for_followed_topics_unique", unique: true
  end

  create_table "thredded_messageboard_users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "thredded_user_detail_id", null: false
    t.integer "thredded_messageboard_id", null: false
    t.datetime "last_seen_at", null: false
    t.index ["thredded_messageboard_id", "last_seen_at"], name: "index_thredded_messageboard_users_for_recently_active"
    t.index ["thredded_messageboard_id", "thredded_user_detail_id"], name: "index_thredded_messageboard_users_primary", unique: true
    t.index ["thredded_user_detail_id"], name: "fk_rails_06e42c62f5"
  end

  create_table "thredded_messageboards", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.text "name", null: false
    t.text "slug"
    t.text "description"
    t.integer "topics_count", default: 0
    t.integer "posts_count", default: 0
    t.integer "position", null: false
    t.integer "last_topic_id"
    t.integer "messageboard_group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "locked", default: false, null: false
    t.index ["messageboard_group_id"], name: "index_thredded_messageboards_on_messageboard_group_id"
    t.index ["slug"], name: "index_thredded_messageboards_on_slug", unique: true, length: 191
  end

  create_table "thredded_notifications_for_followed_topics", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "notifier_key", limit: 90, null: false
    t.boolean "enabled", default: true, null: false
    t.index ["user_id", "notifier_key"], name: "thredded_notifications_for_followed_topics_unique", unique: true
  end

  create_table "thredded_notifications_for_private_topics", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "notifier_key", limit: 90, null: false
    t.boolean "enabled", default: true, null: false
    t.index ["user_id", "notifier_key"], name: "thredded_notifications_for_private_topics_unique", unique: true
  end

  create_table "thredded_post_moderation_records", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "post_id"
    t.integer "messageboard_id"
    t.text "post_content"
    t.integer "post_user_id"
    t.text "post_user_name"
    t.integer "moderator_id"
    t.integer "moderation_state", null: false
    t.integer "previous_moderation_state", null: false
    t.datetime "created_at", null: false
    t.index ["messageboard_id", "created_at"], name: "index_thredded_moderation_records_for_display"
  end

  create_table "thredded_posts", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.text "content"
    t.string "source", limit: 191, default: "web"
    t.integer "postable_id", null: false
    t.integer "messageboard_id", null: false
    t.integer "moderation_state", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content"], name: "thredded_posts_content_fts", type: :fulltext
    t.index ["messageboard_id"], name: "index_thredded_posts_on_messageboard_id"
    t.index ["moderation_state", "updated_at"], name: "index_thredded_posts_for_display"
    t.index ["postable_id"], name: "index_thredded_posts_on_postable_id_and_postable_type"
    t.index ["user_id"], name: "index_thredded_posts_on_user_id"
  end

  create_table "thredded_private_posts", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.text "content"
    t.integer "postable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["postable_id", "created_at"], name: "index_thredded_private_posts_on_postable_id_and_created_at"
  end

  create_table "thredded_private_topics", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "last_user_id"
    t.text "title", null: false
    t.text "slug", null: false
    t.integer "posts_count", default: 0
    t.string "hash_id", limit: 20, null: false
    t.datetime "last_post_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hash_id"], name: "index_thredded_private_topics_on_hash_id"
    t.index ["last_post_at"], name: "index_thredded_private_topics_on_last_post_at"
    t.index ["slug"], name: "index_thredded_private_topics_on_slug", unique: true, length: 191
  end

  create_table "thredded_private_users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "private_topic_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["private_topic_id"], name: "index_thredded_private_users_on_private_topic_id"
    t.index ["user_id"], name: "index_thredded_private_users_on_user_id"
  end

  create_table "thredded_topic_categories", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "topic_id", null: false
    t.integer "category_id", null: false
    t.index ["category_id"], name: "index_thredded_topic_categories_on_category_id"
    t.index ["topic_id"], name: "index_thredded_topic_categories_on_topic_id"
  end

  create_table "thredded_topics", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "last_user_id"
    t.text "title", null: false
    t.text "slug", null: false
    t.integer "messageboard_id", null: false
    t.integer "posts_count", default: 0, null: false
    t.boolean "sticky", default: false, null: false
    t.boolean "locked", default: false, null: false
    t.string "hash_id", limit: 20, null: false
    t.integer "moderation_state", null: false
    t.datetime "last_post_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hash_id"], name: "index_thredded_topics_on_hash_id"
    t.index ["last_post_at"], name: "index_thredded_topics_on_last_post_at"
    t.index ["messageboard_id"], name: "index_thredded_topics_on_messageboard_id"
    t.index ["moderation_state", "sticky", "updated_at"], name: "index_thredded_topics_for_display"
    t.index ["slug"], name: "index_thredded_topics_on_slug", unique: true, length: 191
    t.index ["title"], name: "thredded_topics_title_fts", type: :fulltext
    t.index ["user_id"], name: "index_thredded_topics_on_user_id"
  end

  create_table "thredded_user_details", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "latest_activity_at"
    t.integer "posts_count", default: 0
    t.integer "topics_count", default: 0
    t.datetime "last_seen_at"
    t.integer "moderation_state", default: 0, null: false
    t.datetime "moderation_state_changed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["latest_activity_at"], name: "index_thredded_user_details_on_latest_activity_at"
    t.index ["moderation_state", "moderation_state_changed_at"], name: "index_thredded_user_details_for_moderations"
    t.index ["user_id"], name: "index_thredded_user_details_on_user_id", unique: true
  end

  create_table "thredded_user_messageboard_preferences", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "messageboard_id", null: false
    t.boolean "follow_topics_on_mention", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "auto_follow_topics", default: false, null: false
    t.index ["user_id", "messageboard_id"], name: "thredded_user_messageboard_preferences_user_id_messageboard_id", unique: true
  end

  create_table "thredded_user_post_notifications", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "post_id", null: false
    t.datetime "notified_at", null: false
    t.index ["post_id"], name: "index_thredded_user_post_notifications_on_post_id"
    t.index ["user_id", "post_id"], name: "index_thredded_user_post_notifications_on_user_id_and_post_id", unique: true
  end

  create_table "thredded_user_preferences", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.boolean "follow_topics_on_mention", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "auto_follow_topics", default: false, null: false
    t.index ["user_id"], name: "index_thredded_user_preferences_on_user_id", unique: true
  end

  create_table "thredded_user_private_topic_read_states", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "postable_id", null: false
    t.datetime "read_at", null: false
    t.integer "unread_posts_count", default: 0, null: false
    t.integer "read_posts_count", default: 0, null: false
    t.index ["user_id", "postable_id"], name: "thredded_user_private_topic_read_states_user_postable", unique: true
  end

  create_table "thredded_user_topic_follows", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "topic_id", null: false
    t.datetime "created_at", null: false
    t.integer "reason", limit: 1
    t.index ["user_id", "topic_id"], name: "thredded_user_topic_follows_user_topic", unique: true
  end

  create_table "thredded_user_topic_read_states", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "postable_id", null: false
    t.datetime "read_at", null: false
    t.integer "unread_posts_count", default: 0, null: false
    t.integer "read_posts_count", default: 0, null: false
    t.integer "messageboard_id", null: false
    t.index ["messageboard_id"], name: "index_thredded_user_topic_read_states_on_messageboard_id"
    t.index ["user_id", "messageboard_id"], name: "thredded_user_topic_read_states_user_messageboard"
    t.index ["user_id", "postable_id"], name: "thredded_user_topic_read_states_user_postable", unique: true
  end

  create_table "user_messages", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "private_message_id", null: false
    t.string "method"
    t.boolean "unread", default: true
    t.boolean "deleted", default: false
  end

  create_table "users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
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
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "guest", default: false
    t.string "username"
    t.string "role"
    t.boolean "email_is_public", default: false
    t.text "bio"
    t.boolean "reviewed", default: false
    t.integer "reviewed_by_id"
    t.datetime "reviewed_at"
    t.integer "created_by_id"
    t.integer "updated_by_id"
    t.string "fullname"
    t.boolean "active", default: true
    t.string "institutional_affiliation"
    t.integer "bookmark_tracker", default: 0
    t.boolean "backup", default: true
    t.boolean "active_survey", default: true
    t.index ["created_by_id"], name: "index_users_on_created_by_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["reviewed_by_id"], name: "index_users_on_reviewed_by_id"
    t.index ["updated_by_id"], name: "index_users_on_updated_by_id"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "version_associations", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "version_id"
    t.string "foreign_key_name", null: false
    t.integer "foreign_key_id"
    t.index ["foreign_key_name", "foreign_key_id"], name: "index_version_associations_on_foreign_key"
    t.index ["version_id"], name: "index_version_associations_on_version_id"
  end

  create_table "versions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.text "object_changes"
    t.integer "transaction_id"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
    t.index ["transaction_id"], name: "index_versions_on_transaction_id"
  end

  create_table "watches", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "watched_id"
    t.string "watched_type"
    t.integer "user_id"
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
  add_foreign_key "thredded_messageboard_users", "thredded_messageboards", on_delete: :cascade
  add_foreign_key "thredded_messageboard_users", "thredded_user_details", on_delete: :cascade
  add_foreign_key "users", "users", column: "created_by_id"
  add_foreign_key "users", "users", column: "reviewed_by_id"
  add_foreign_key "users", "users", column: "updated_by_id"
end
