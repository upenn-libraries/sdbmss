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

ActiveRecord::Schema.define(version: 20170221150134) do

  create_table "activities", force: :cascade do |t|
    t.string   "item_type",      limit: 255, null: false
    t.integer  "item_id",        limit: 4
    t.string   "event",          limit: 255, null: false
    t.integer  "user_id",        limit: 4
    t.datetime "created_at"
    t.integer  "transaction_id", limit: 4
  end

  create_table "bookmarks", force: :cascade do |t|
    t.integer  "user_id",       limit: 4,     null: false
    t.string   "user_type",     limit: 255
    t.string   "document_id",   limit: 255
    t.string   "title",         limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "document_type", limit: 255
    t.text     "tags",          limit: 65535
  end

  add_index "bookmarks", ["user_id"], name: "index_bookmarks_on_user_id", using: :btree

  create_table "comments", force: :cascade do |t|
    t.text     "comment",          limit: 65535
    t.boolean  "public",                         default: true
    t.boolean  "is_correction",                  default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "reviewed",                       default: false
    t.datetime "reviewed_at"
    t.boolean  "deleted",                        default: false
    t.integer  "created_by_id",    limit: 4
    t.integer  "updated_by_id",    limit: 4
    t.integer  "reviewed_by_id",   limit: 4
    t.boolean  "is_accepted",                    default: false
    t.integer  "commentable_id",   limit: 4
    t.string   "commentable_type", limit: 255
  end

  add_index "comments", ["created_by_id"], name: "index_comments_on_created_by_id", using: :btree
  add_index "comments", ["reviewed_by_id"], name: "index_comments_on_reviewed_by_id", using: :btree
  add_index "comments", ["updated_by_id"], name: "index_comments_on_updated_by_id", using: :btree

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   limit: 4,     default: 0, null: false
    t.integer  "attempts",   limit: 4,     default: 0, null: false
    t.text     "handler",    limit: 65535,             null: false
    t.text     "last_error", limit: 65535
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",  limit: 255
    t.string   "queue",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "dericci_game_records", force: :cascade do |t|
    t.integer "dericci_game_id",   limit: 4
    t.integer "dericci_record_id", limit: 4
  end

  create_table "dericci_games", force: :cascade do |t|
    t.integer  "created_by_id", limit: 4
    t.boolean  "reviewed"
    t.integer  "skipped",       limit: 4
    t.integer  "completed",     limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "dericci_games", ["created_by_id"], name: "index_dericci_games_on_created_by_id", using: :btree

  create_table "dericci_links", force: :cascade do |t|
    t.integer  "name_id",           limit: 4
    t.integer  "dericci_record_id", limit: 4
    t.datetime "created_at"
    t.integer  "created_by_id",     limit: 4
    t.datetime "updated_at"
    t.integer  "updated_by_id",     limit: 4
    t.boolean  "approved"
    t.integer  "dericci_game_id",   limit: 4
    t.text     "other_info",        limit: 65535
    t.integer  "reliability",       limit: 4,     default: 0
  end

  add_index "dericci_links", ["created_by_id"], name: "index_dericci_links_on_created_by_id", using: :btree
  add_index "dericci_links", ["updated_by_id"], name: "index_dericci_links_on_updated_by_id", using: :btree

  create_table "dericci_records", force: :cascade do |t|
    t.string  "name",         limit: 255
    t.string  "dates",        limit: 255
    t.string  "place",        limit: 255
    t.string  "url",          limit: 255
    t.integer "cards",        limit: 4
    t.string  "size",         limit: 255
    t.text    "other_info",   limit: 16777215
    t.string  "senate_house", limit: 255
  end

  create_table "downloads", force: :cascade do |t|
    t.string   "filename",      limit: 255
    t.integer  "status",        limit: 4,   default: 0
    t.integer  "user_id",       limit: 4
    t.integer  "created_by_id", limit: 4
    t.datetime "created_at"
  end

  add_index "downloads", ["created_by_id"], name: "index_downloads_on_created_by_id", using: :btree
  add_index "downloads", ["user_id"], name: "index_downloads_on_user_id", using: :btree

  create_table "entries", force: :cascade do |t|
    t.integer  "source_id",                limit: 4
    t.string   "catalog_or_lot_number",    limit: 255
    t.integer  "folios",                   limit: 4
    t.integer  "num_columns",              limit: 4
    t.integer  "num_lines",                limit: 4
    t.integer  "height",                   limit: 4
    t.integer  "width",                    limit: 4
    t.string   "alt_size",                 limit: 255
    t.string   "manuscript_binding",       limit: 1024
    t.text     "other_info",               limit: 65535
    t.string   "manuscript_link",          limit: 1024
    t.integer  "miniatures_fullpage",      limit: 4
    t.integer  "miniatures_large",         limit: 4
    t.integer  "miniatures_small",         limit: 4
    t.integer  "miniatures_unspec_size",   limit: 4
    t.integer  "initials_historiated",     limit: 4
    t.integer  "initials_decorated",       limit: 4
    t.boolean  "approved",                               default: false
    t.boolean  "deleted",                                default: false
    t.datetime "created_at"
    t.integer  "created_by_id",            limit: 4
    t.datetime "updated_at"
    t.integer  "updated_by_id",            limit: 4
    t.integer  "institution_id",           limit: 4
    t.string   "transaction_type",         limit: 255
    t.integer  "approved_by_id",           limit: 4
    t.datetime "approved_at"
    t.integer  "touch_count",              limit: 4,     default: 0,     null: false
    t.boolean  "deprecated",                             default: false
    t.integer  "superceded_by_id",         limit: 4
    t.boolean  "unverified_legacy_record",               default: false
    t.boolean  "confirmed",                              default: false
  end

  add_index "entries", ["approved_by_id"], name: "index_entries_on_approved_by_id", using: :btree
  add_index "entries", ["created_by_id"], name: "index_entries_on_created_by_id", using: :btree
  add_index "entries", ["institution_id"], name: "index_entries_on_institution_id", using: :btree
  add_index "entries", ["source_id"], name: "index_entries_on_source_id", using: :btree
  add_index "entries", ["superceded_by_id"], name: "index_entries_on_superceded_by_id", using: :btree
  add_index "entries", ["updated_by_id"], name: "index_entries_on_updated_by_id", using: :btree

  create_table "entry_artists", force: :cascade do |t|
    t.integer  "entry_id",               limit: 4
    t.integer  "artist_id",              limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "uncertain_in_source",                default: false
    t.boolean  "supplied_by_data_entry",             default: false
    t.string   "observed_name",          limit: 255
    t.integer  "order",                  limit: 4
    t.string   "role",                   limit: 255
  end

  add_index "entry_artists", ["artist_id"], name: "index_entry_artists_on_artist_id", using: :btree
  add_index "entry_artists", ["entry_id"], name: "index_entry_artists_on_entry_id", using: :btree

  create_table "entry_authors", force: :cascade do |t|
    t.integer  "entry_id",               limit: 4
    t.integer  "author_id",              limit: 4
    t.string   "observed_name",          limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "role",                   limit: 255
    t.boolean  "uncertain_in_source",                default: false
    t.boolean  "supplied_by_data_entry",             default: false
    t.integer  "order",                  limit: 4
  end

  add_index "entry_authors", ["author_id"], name: "index_entry_authors_on_author_id", using: :btree
  add_index "entry_authors", ["entry_id"], name: "index_entry_authors_on_entry_id", using: :btree

  create_table "entry_changes", force: :cascade do |t|
    t.integer  "entry_id",      limit: 4
    t.string   "column",        limit: 255
    t.text     "changed_from",  limit: 65535
    t.text     "changed_to",    limit: 65535
    t.string   "change_type",   limit: 255
    t.datetime "change_date"
    t.integer  "changed_by_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "entry_changes", ["changed_by_id"], name: "index_entry_changes_on_changed_by_id", using: :btree
  add_index "entry_changes", ["entry_id"], name: "index_entry_changes_on_entry_id", using: :btree

  create_table "entry_comments", force: :cascade do |t|
    t.integer "entry_id",   limit: 4
    t.integer "comment_id", limit: 4
  end

  add_index "entry_comments", ["comment_id"], name: "index_entry_comments_on_comment_id", using: :btree
  add_index "entry_comments", ["entry_id"], name: "index_entry_comments_on_entry_id", using: :btree

  create_table "entry_dates", force: :cascade do |t|
    t.integer  "entry_id",               limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "observed_date",          limit: 255
    t.string   "date_normalized_start",  limit: 255
    t.string   "date_normalized_end",    limit: 255
    t.boolean  "uncertain_in_source",                default: false
    t.boolean  "supplied_by_data_entry",             default: false
    t.integer  "order",                  limit: 4
  end

  add_index "entry_dates", ["entry_id"], name: "index_entry_dates_on_entry_id", using: :btree

  create_table "entry_languages", force: :cascade do |t|
    t.integer  "entry_id",               limit: 4
    t.integer  "language_id",            limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "uncertain_in_source",              default: false
    t.boolean  "supplied_by_data_entry",           default: false
    t.integer  "order",                  limit: 4
  end

  add_index "entry_languages", ["entry_id"], name: "index_entry_languages_on_entry_id", using: :btree
  add_index "entry_languages", ["language_id"], name: "index_entry_languages_on_language_id", using: :btree

  create_table "entry_manuscript_activities", force: :cascade do |t|
    t.integer "activity_id",    limit: 4
    t.integer "entry_id",       limit: 4
    t.integer "manuscript_id",  limit: 4
    t.integer "transaction_id", limit: 4
  end

  add_index "entry_manuscript_activities", ["activity_id"], name: "index_entry_manuscript_activities_on_activity_id", using: :btree

  create_table "entry_manuscripts", force: :cascade do |t|
    t.integer  "entry_id",       limit: 4
    t.integer  "manuscript_id",  limit: 4
    t.string   "relation_type",  limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "reviewed",                   default: false
    t.integer  "reviewed_by_id", limit: 4
    t.datetime "reviewed_at"
    t.integer  "created_by_id",  limit: 4
    t.integer  "updated_by_id",  limit: 4
  end

  add_index "entry_manuscripts", ["created_by_id"], name: "index_entry_manuscripts_on_created_by_id", using: :btree
  add_index "entry_manuscripts", ["entry_id"], name: "index_entry_manuscripts_on_entry_id", using: :btree
  add_index "entry_manuscripts", ["manuscript_id"], name: "index_entry_manuscripts_on_manuscript_id", using: :btree
  add_index "entry_manuscripts", ["reviewed_by_id"], name: "index_entry_manuscripts_on_reviewed_by_id", using: :btree
  add_index "entry_manuscripts", ["updated_by_id"], name: "index_entry_manuscripts_on_updated_by_id", using: :btree

  create_table "entry_materials", force: :cascade do |t|
    t.integer  "entry_id",               limit: 4
    t.string   "material",               limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "uncertain_in_source",                default: false
    t.boolean  "supplied_by_data_entry",             default: false
    t.integer  "order",                  limit: 4
  end

  add_index "entry_materials", ["entry_id"], name: "index_entry_materials_on_entry_id", using: :btree

  create_table "entry_places", force: :cascade do |t|
    t.integer  "entry_id",               limit: 4
    t.integer  "place_id",               limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "uncertain_in_source",                default: false
    t.boolean  "supplied_by_data_entry",             default: false
    t.string   "observed_name",          limit: 255
    t.integer  "order",                  limit: 4
  end

  add_index "entry_places", ["entry_id"], name: "index_entry_places_on_entry_id", using: :btree
  add_index "entry_places", ["place_id"], name: "index_entry_places_on_place_id", using: :btree

  create_table "entry_scribes", force: :cascade do |t|
    t.integer  "entry_id",               limit: 4
    t.integer  "scribe_id",              limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "uncertain_in_source",                default: false
    t.boolean  "supplied_by_data_entry",             default: false
    t.string   "observed_name",          limit: 255
    t.integer  "order",                  limit: 4
  end

  add_index "entry_scribes", ["entry_id"], name: "index_entry_scribes_on_entry_id", using: :btree
  add_index "entry_scribes", ["scribe_id"], name: "index_entry_scribes_on_scribe_id", using: :btree

  create_table "entry_titles", force: :cascade do |t|
    t.integer  "entry_id",               limit: 4
    t.string   "title",                  limit: 2048
    t.string   "common_title",           limit: 2048
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "uncertain_in_source",                 default: false
    t.boolean  "supplied_by_data_entry",              default: false
    t.integer  "order",                  limit: 4
  end

  add_index "entry_titles", ["entry_id"], name: "index_entry_titles_on_entry_id", using: :btree

  create_table "entry_uses", force: :cascade do |t|
    t.integer  "entry_id",   limit: 4
    t.string   "use",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "order",      limit: 4
  end

  add_index "entry_uses", ["entry_id"], name: "index_entry_uses_on_entry_id", using: :btree

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string   "slug",           limit: 191, null: false
    t.integer  "sluggable_id",   limit: 4,   null: false
    t.string   "sluggable_type", limit: 50
    t.string   "scope",          limit: 191
    t.datetime "created_at",                 null: false
  end

  add_index "friendly_id_slugs", ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true, using: :btree
  add_index "friendly_id_slugs", ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type", using: :btree
  add_index "friendly_id_slugs", ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id", using: :btree
  add_index "friendly_id_slugs", ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type", using: :btree

  create_table "group_records", force: :cascade do |t|
    t.integer "record_id",   limit: 4
    t.string  "record_type", limit: 255
    t.integer "group_id",    limit: 4
  end

  create_table "group_users", force: :cascade do |t|
    t.integer "group_id",      limit: 4
    t.integer "user_id",       limit: 4
    t.string  "role",          limit: 255, default: "Member"
    t.boolean "confirmed",                 default: false
    t.integer "created_by_id", limit: 4
  end

  create_table "groups", force: :cascade do |t|
    t.text     "name",          limit: 65535
    t.boolean  "public",                      default: false
    t.integer  "created_by_id", limit: 4
    t.integer  "updated_by_id", limit: 4
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.text     "description",   limit: 65535
  end

  create_table "languages", force: :cascade do |t|
    t.string   "name",           limit: 255
    t.datetime "created_at"
    t.integer  "created_by_id",  limit: 4
    t.datetime "updated_at"
    t.integer  "updated_by_id",  limit: 4
    t.integer  "entries_count",  limit: 4,   default: 0,     null: false
    t.boolean  "deleted",                    default: false
    t.boolean  "reviewed",                   default: false
    t.integer  "reviewed_by_id", limit: 4
    t.datetime "reviewed_at"
  end

  add_index "languages", ["created_by_id"], name: "index_languages_on_created_by_id", using: :btree
  add_index "languages", ["name"], name: "index_languages_on_name", unique: true, using: :btree
  add_index "languages", ["reviewed_by_id"], name: "index_languages_on_reviewed_by_id", using: :btree
  add_index "languages", ["updated_by_id"], name: "index_languages_on_updated_by_id", using: :btree

  create_table "legacy_data_issues", force: :cascade do |t|
    t.string  "table_name",  limit: 255
    t.integer "record_id",   limit: 4
    t.string  "issue_type",  limit: 255
    t.string  "explanation", limit: 1024
  end

  create_table "manuscript_comments", force: :cascade do |t|
    t.integer "manuscript_id", limit: 4
    t.integer "comment_id",    limit: 4
  end

  add_index "manuscript_comments", ["comment_id"], name: "index_manuscript_comments_on_comment_id", using: :btree
  add_index "manuscript_comments", ["manuscript_id"], name: "index_manuscript_comments_on_manuscript_id", using: :btree

  create_table "manuscripts", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id",  limit: 4
    t.integer  "updated_by_id",  limit: 4
    t.string   "name",           limit: 255
    t.integer  "entries_count",  limit: 4,   default: 0,     null: false
    t.string   "location",       limit: 255
    t.boolean  "reviewed",                   default: false
    t.integer  "reviewed_by_id", limit: 4
    t.datetime "reviewed_at"
    t.string   "url",            limit: 255
  end

  add_index "manuscripts", ["created_by_id"], name: "index_manuscripts_on_created_by_id", using: :btree
  add_index "manuscripts", ["reviewed_by_id"], name: "index_manuscripts_on_reviewed_by_id", using: :btree
  add_index "manuscripts", ["updated_by_id"], name: "index_manuscripts_on_updated_by_id", using: :btree

  create_table "names", force: :cascade do |t|
    t.string   "name",                limit: 255
    t.integer  "entry_id",            limit: 4
    t.string   "viaf_id",             limit: 255
    t.boolean  "is_artist",                         default: false
    t.boolean  "is_author",                         default: false
    t.boolean  "is_scribe",                         default: false
    t.boolean  "is_provenance_agent",               default: false
    t.datetime "created_at"
    t.integer  "created_by_id",       limit: 4
    t.datetime "updated_at"
    t.integer  "updated_by_id",       limit: 4
    t.integer  "authors_count",       limit: 4,     default: 0,     null: false
    t.integer  "artists_count",       limit: 4,     default: 0,     null: false
    t.integer  "scribes_count",       limit: 4,     default: 0,     null: false
    t.integer  "source_agents_count", limit: 4,     default: 0,     null: false
    t.integer  "sale_agents_count",   limit: 4,     default: 0,     null: false
    t.boolean  "deleted",                           default: false
    t.text     "other_info",          limit: 65535
    t.boolean  "reviewed",                          default: false
    t.integer  "reviewed_by_id",      limit: 4
    t.datetime "reviewed_at"
    t.integer  "provenance_count",    limit: 4,     default: 0,     null: false
    t.boolean  "confirmed",                         default: false
  end

  add_index "names", ["created_by_id"], name: "index_names_on_created_by_id", using: :btree
  add_index "names", ["entry_id"], name: "index_names_on_entry_id", using: :btree
  add_index "names", ["is_artist"], name: "index_names_on_is_artist", using: :btree
  add_index "names", ["is_author"], name: "index_names_on_is_author", using: :btree
  add_index "names", ["is_provenance_agent"], name: "index_names_on_is_provenance_agent", using: :btree
  add_index "names", ["is_scribe"], name: "index_names_on_is_scribe", using: :btree
  add_index "names", ["name"], name: "index_names_on_name", unique: true, using: :btree
  add_index "names", ["reviewed_by_id"], name: "index_names_on_reviewed_by_id", using: :btree
  add_index "names", ["updated_by_id"], name: "index_names_on_updated_by_id", using: :btree

  create_table "notification_settings", force: :cascade do |t|
    t.integer  "user_id",              limit: 4
    t.boolean  "on_update"
    t.boolean  "on_comment"
    t.boolean  "on_reply"
    t.datetime "created_at",                                     null: false
    t.datetime "updated_at",                                     null: false
    t.boolean  "on_message",                     default: true
    t.boolean  "email_on_message",               default: true
    t.boolean  "email_on_comment",               default: false
    t.boolean  "email_on_reply",                 default: false
    t.boolean  "email_on_update",                default: false
    t.boolean  "on_new_user",                    default: false
    t.boolean  "email_on_new_user",              default: false
    t.boolean  "on_group",                       default: true
    t.boolean  "email_on_group",                 default: false
    t.boolean  "on_all_comment",                 default: true
    t.boolean  "email_on_all_comment",           default: false
    t.boolean  "auto_watch",                     default: true
  end

  create_table "notifications", force: :cascade do |t|
    t.string   "message",       limit: 255
    t.string   "category",      limit: 255
    t.boolean  "active",                    default: true
    t.integer  "user_id",       limit: 4
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.string   "url",           limit: 255
    t.string   "title",         limit: 255
    t.integer  "notified_id",   limit: 4
    t.string   "notified_type", limit: 255
  end

  create_table "pages", force: :cascade do |t|
    t.string   "filename",   limit: 255
    t.string   "name",       limit: 255
    t.string   "category",   limit: 255, default: "upload"
    t.datetime "created_at",             default: '2017-01-12 15:31:00'
    t.datetime "updated_at",             default: '2017-01-12 15:31:00'
  end

  add_index "pages", ["filename"], name: "index_pages_on_filename", unique: true, using: :btree
  add_index "pages", ["name"], name: "index_pages_on_name", unique: true, using: :btree

  create_table "places", force: :cascade do |t|
    t.string   "name",           limit: 255
    t.integer  "entry_id",       limit: 4
    t.datetime "created_at"
    t.integer  "created_by_id",  limit: 4
    t.datetime "updated_at"
    t.integer  "updated_by_id",  limit: 4
    t.integer  "entries_count",  limit: 4,   default: 0,     null: false
    t.boolean  "deleted",                    default: false
    t.boolean  "reviewed",                   default: false
    t.integer  "reviewed_by_id", limit: 4
    t.datetime "reviewed_at"
  end

  add_index "places", ["created_by_id"], name: "index_places_on_created_by_id", using: :btree
  add_index "places", ["entry_id"], name: "index_places_on_entry_id", using: :btree
  add_index "places", ["name"], name: "index_places_on_name", unique: true, using: :btree
  add_index "places", ["reviewed_by_id"], name: "index_places_on_reviewed_by_id", using: :btree
  add_index "places", ["updated_by_id"], name: "index_places_on_updated_by_id", using: :btree

  create_table "private_messages", force: :cascade do |t|
    t.text     "message",            limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "deleted",                          default: false
    t.integer  "created_by_id",      limit: 4
    t.integer  "updated_by_id",      limit: 4
    t.integer  "user_id",            limit: 4
    t.integer  "private_message_id", limit: 4
    t.text     "title",              limit: 65535
  end

  add_index "private_messages", ["created_by_id"], name: "index_private_messages_on_created_by_id", using: :btree
  add_index "private_messages", ["private_message_id"], name: "index_private_messages_on_private_message_id", using: :btree
  add_index "private_messages", ["updated_by_id"], name: "index_private_messages_on_updated_by_id", using: :btree
  add_index "private_messages", ["user_id"], name: "index_private_messages_on_user_id", using: :btree

  create_table "provenance", force: :cascade do |t|
    t.integer  "entry_id",                         limit: 4
    t.integer  "order",                            limit: 4
    t.string   "observed_name",                    limit: 255
    t.integer  "provenance_agent_id",              limit: 4
    t.string   "acquisition_method",               limit: 255
    t.boolean  "direct_transfer",                                default: false
    t.datetime "created_at"
    t.integer  "created_by_id",                    limit: 4
    t.datetime "updated_at"
    t.integer  "updated_by_id",                    limit: 4
    t.string   "start_date",                       limit: 255
    t.string   "start_date_normalized_start",      limit: 255
    t.string   "start_date_normalized_end",        limit: 255
    t.string   "end_date",                         limit: 255
    t.string   "end_date_normalized_start",        limit: 255
    t.string   "end_date_normalized_end",          limit: 255
    t.text     "comment",                          limit: 65535
    t.boolean  "uncertain_in_source",                            default: false
    t.boolean  "supplied_by_data_entry",                         default: false
    t.string   "associated_date",                  limit: 255
    t.string   "associated_date_normalized_start", limit: 255
    t.string   "associated_date_normalized_end",   limit: 255
  end

  add_index "provenance", ["entry_id"], name: "index_provenance_on_entry_id", using: :btree
  add_index "provenance", ["provenance_agent_id"], name: "index_provenance_on_provenance_agent_id", using: :btree

  create_table "ratings", force: :cascade do |t|
    t.integer  "user_id",      limit: 4
    t.integer  "ratable_id",   limit: 4
    t.string   "ratable_type", limit: 255
    t.string   "user_level",   limit: 255
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "replies", force: :cascade do |t|
    t.text     "reply",         limit: 65535
    t.integer  "comment_id",    limit: 4
    t.integer  "created_by_id", limit: 4
    t.integer  "updated_by_id", limit: 4
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.boolean  "deleted",                     default: false
  end

  add_index "replies", ["comment_id"], name: "index_replies_on_comment_id", using: :btree
  add_index "replies", ["created_by_id"], name: "index_replies_on_created_by_id", using: :btree
  add_index "replies", ["updated_by_id"], name: "index_replies_on_updated_by_id", using: :btree

  create_table "sale_agents", force: :cascade do |t|
    t.integer  "sale_id",                limit: 4
    t.string   "observed_name",          limit: 255
    t.integer  "agent_id",               limit: 4
    t.string   "role",                   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "uncertain_in_source",                default: false
    t.boolean  "supplied_by_data_entry",             default: false
  end

  add_index "sale_agents", ["agent_id"], name: "index_sale_agents_on_agent_id", using: :btree
  add_index "sale_agents", ["observed_name"], name: "index_sale_agents_on_observed_name", using: :btree
  add_index "sale_agents", ["sale_id"], name: "index_sale_agents_on_sale_id", using: :btree

  create_table "sales", force: :cascade do |t|
    t.integer  "entry_id",       limit: 4
    t.string   "date",           limit: 255
    t.decimal  "price",                      precision: 20, scale: 2
    t.string   "currency",       limit: 255
    t.string   "other_currency", limit: 255
    t.string   "sold",           limit: 255
    t.datetime "created_at"
    t.integer  "created_by_id",  limit: 4
    t.datetime "updated_at"
    t.integer  "updated_by_id",  limit: 4
  end

  add_index "sales", ["created_by_id"], name: "index_sales_on_created_by_id", using: :btree
  add_index "sales", ["entry_id"], name: "index_sales_on_entry_id", using: :btree
  add_index "sales", ["updated_by_id"], name: "index_sales_on_updated_by_id", using: :btree

  create_table "searches", force: :cascade do |t|
    t.text     "query_params", limit: 65535
    t.integer  "user_id",      limit: 4
    t.string   "user_type",    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "searches", ["user_id"], name: "index_searches_on_user_id", using: :btree

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", limit: 255,   null: false
    t.text     "data",       limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", unique: true, using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "source_agents", force: :cascade do |t|
    t.integer  "source_id",  limit: 4
    t.integer  "agent_id",   limit: 4
    t.string   "role",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "source_agents", ["agent_id"], name: "index_source_agents_on_agent_id", using: :btree
  add_index "source_agents", ["source_id"], name: "index_source_agents_on_source_id", using: :btree

  create_table "source_comments", force: :cascade do |t|
    t.integer "source_id",  limit: 4
    t.integer "comment_id", limit: 4
  end

  add_index "source_comments", ["comment_id"], name: "index_source_comments_on_comment_id", using: :btree
  add_index "source_comments", ["source_id"], name: "index_source_comments_on_source_id", using: :btree

  create_table "source_types", force: :cascade do |t|
    t.string  "name",                           limit: 255
    t.string  "display_name",                   limit: 255
    t.string  "entries_transaction_field",      limit: 255
    t.boolean "entries_have_institution_field"
  end

  create_table "sources", force: :cascade do |t|
    t.string   "date",                 limit: 255
    t.string   "title",                limit: 512
    t.string   "author",               limit: 255
    t.string   "whether_mss",          limit: 255
    t.string   "link",                 limit: 512
    t.boolean  "in_manuscript_table"
    t.boolean  "deleted"
    t.text     "other_info",           limit: 65535
    t.string   "status",               limit: 255
    t.string   "hidden",               limit: 255
    t.datetime "created_at"
    t.integer  "created_by_id",        limit: 4
    t.datetime "updated_at"
    t.integer  "updated_by_id",        limit: 4
    t.integer  "entries_count",        limit: 4,     default: 0,     null: false
    t.string   "location_institution", limit: 255
    t.string   "location",             limit: 255
    t.string   "medium",               limit: 255
    t.string   "date_accessed",        limit: 255
    t.integer  "source_type_id",       limit: 4
    t.boolean  "reviewed",                           default: false
    t.integer  "reviewed_by_id",       limit: 4
    t.datetime "reviewed_at"
  end

  add_index "sources", ["created_by_id"], name: "index_sources_on_created_by_id", using: :btree
  add_index "sources", ["reviewed_by_id"], name: "index_sources_on_reviewed_by_id", using: :btree
  add_index "sources", ["source_type_id"], name: "index_sources_on_source_type_id", using: :btree
  add_index "sources", ["updated_by_id"], name: "index_sources_on_updated_by_id", using: :btree

  create_table "thredded_categories", force: :cascade do |t|
    t.integer  "messageboard_id", limit: 4,   null: false
    t.string   "name",            limit: 191, null: false
    t.string   "description",     limit: 255
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.string   "slug",            limit: 191, null: false
  end

  add_index "thredded_categories", ["messageboard_id", "slug"], name: "index_thredded_categories_on_messageboard_id_and_slug", unique: true, using: :btree
  add_index "thredded_categories", ["messageboard_id"], name: "index_thredded_categories_on_messageboard_id", using: :btree
  add_index "thredded_categories", ["name"], name: "thredded_categories_name_ci", using: :btree

  create_table "thredded_messageboard_groups", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.integer  "position",   limit: 4,   null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "thredded_messageboard_notifications_for_followed_topics", force: :cascade do |t|
    t.integer "user_id",         limit: 4,                 null: false
    t.integer "messageboard_id", limit: 4,                 null: false
    t.string  "notifier_key",    limit: 90,                null: false
    t.boolean "enabled",                    default: true, null: false
  end

  add_index "thredded_messageboard_notifications_for_followed_topics", ["user_id", "messageboard_id", "notifier_key"], name: "thredded_messageboard_notifications_for_followed_topics_unique", unique: true, using: :btree

  create_table "thredded_messageboard_users", force: :cascade do |t|
    t.integer  "thredded_user_detail_id",  limit: 4, null: false
    t.integer  "thredded_messageboard_id", limit: 4, null: false
    t.datetime "last_seen_at",                       null: false
  end

  add_index "thredded_messageboard_users", ["thredded_messageboard_id", "last_seen_at"], name: "index_thredded_messageboard_users_for_recently_active", using: :btree
  add_index "thredded_messageboard_users", ["thredded_messageboard_id", "thredded_user_detail_id"], name: "index_thredded_messageboard_users_primary", using: :btree
  add_index "thredded_messageboard_users", ["thredded_user_detail_id"], name: "fk_rails_06e42c62f5", using: :btree

  create_table "thredded_messageboards", force: :cascade do |t|
    t.string   "name",                  limit: 191,               null: false
    t.string   "slug",                  limit: 191
    t.text     "description",           limit: 65535
    t.integer  "topics_count",          limit: 4,     default: 0
    t.integer  "posts_count",           limit: 4,     default: 0
    t.integer  "position",              limit: 4,                 null: false
    t.integer  "last_topic_id",         limit: 4
    t.integer  "messageboard_group_id", limit: 4
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
  end

  add_index "thredded_messageboards", ["messageboard_group_id"], name: "index_thredded_messageboards_on_messageboard_group_id", using: :btree
  add_index "thredded_messageboards", ["slug"], name: "index_thredded_messageboards_on_slug", using: :btree

  create_table "thredded_notifications_for_followed_topics", force: :cascade do |t|
    t.integer "user_id",      limit: 4,                 null: false
    t.string  "notifier_key", limit: 90,                null: false
    t.boolean "enabled",                 default: true, null: false
  end

  add_index "thredded_notifications_for_followed_topics", ["user_id", "notifier_key"], name: "thredded_notifications_for_followed_topics_unique", unique: true, using: :btree

  create_table "thredded_notifications_for_private_topics", force: :cascade do |t|
    t.integer "user_id",      limit: 4,                 null: false
    t.string  "notifier_key", limit: 90,                null: false
    t.boolean "enabled",                 default: true, null: false
  end

  add_index "thredded_notifications_for_private_topics", ["user_id", "notifier_key"], name: "thredded_notifications_for_private_topics_unique", unique: true, using: :btree

  create_table "thredded_post_moderation_records", force: :cascade do |t|
    t.integer  "post_id",                   limit: 4
    t.integer  "messageboard_id",           limit: 4
    t.text     "post_content",              limit: 65535
    t.integer  "post_user_id",              limit: 4
    t.text     "post_user_name",            limit: 65535
    t.integer  "moderator_id",              limit: 4
    t.integer  "moderation_state",          limit: 4,     null: false
    t.integer  "previous_moderation_state", limit: 4,     null: false
    t.datetime "created_at",                              null: false
  end

  add_index "thredded_post_moderation_records", ["messageboard_id", "created_at"], name: "index_thredded_moderation_records_for_display", using: :btree

  create_table "thredded_post_notifications", force: :cascade do |t|
    t.string   "email",      limit: 191, null: false
    t.integer  "post_id",    limit: 4,   null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "post_type",  limit: 191
  end

  add_index "thredded_post_notifications", ["post_id", "post_type"], name: "index_thredded_post_notifications_on_post", using: :btree

  create_table "thredded_posts", force: :cascade do |t|
    t.integer  "user_id",          limit: 4
    t.text     "content",          limit: 65535
    t.string   "ip",               limit: 255
    t.string   "source",           limit: 255,   default: "web"
    t.integer  "postable_id",      limit: 4,                     null: false
    t.integer  "messageboard_id",  limit: 4,                     null: false
    t.integer  "moderation_state", limit: 4,                     null: false
    t.datetime "created_at",                                     null: false
    t.datetime "updated_at",                                     null: false
  end

  add_index "thredded_posts", ["content"], name: "thredded_posts_content_fts", type: :fulltext
  add_index "thredded_posts", ["messageboard_id"], name: "index_thredded_posts_on_messageboard_id", using: :btree
  add_index "thredded_posts", ["moderation_state", "updated_at"], name: "index_thredded_posts_for_display", using: :btree
  add_index "thredded_posts", ["postable_id"], name: "index_thredded_posts_on_postable_id_and_postable_type", using: :btree
  add_index "thredded_posts", ["user_id"], name: "index_thredded_posts_on_user_id", using: :btree

  create_table "thredded_private_posts", force: :cascade do |t|
    t.integer  "user_id",     limit: 4
    t.text     "content",     limit: 65535
    t.integer  "postable_id", limit: 4,     null: false
    t.string   "ip",          limit: 255
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "thredded_private_topics", force: :cascade do |t|
    t.integer  "user_id",      limit: 4
    t.integer  "last_user_id", limit: 4
    t.string   "title",        limit: 255,             null: false
    t.string   "slug",         limit: 191,             null: false
    t.integer  "posts_count",  limit: 4,   default: 0
    t.string   "hash_id",      limit: 191,             null: false
    t.datetime "last_post_at"
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
  end

  add_index "thredded_private_topics", ["hash_id"], name: "index_thredded_private_topics_on_hash_id", using: :btree
  add_index "thredded_private_topics", ["slug"], name: "index_thredded_private_topics_on_slug", using: :btree

  create_table "thredded_private_users", force: :cascade do |t|
    t.integer  "private_topic_id", limit: 4
    t.integer  "user_id",          limit: 4
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "thredded_private_users", ["private_topic_id"], name: "index_thredded_private_users_on_private_topic_id", using: :btree
  add_index "thredded_private_users", ["user_id"], name: "index_thredded_private_users_on_user_id", using: :btree

  create_table "thredded_topic_categories", force: :cascade do |t|
    t.integer "topic_id",    limit: 4, null: false
    t.integer "category_id", limit: 4, null: false
  end

  add_index "thredded_topic_categories", ["category_id"], name: "index_thredded_topic_categories_on_category_id", using: :btree
  add_index "thredded_topic_categories", ["topic_id"], name: "index_thredded_topic_categories_on_topic_id", using: :btree

  create_table "thredded_topics", force: :cascade do |t|
    t.integer  "user_id",          limit: 4
    t.integer  "last_user_id",     limit: 4
    t.string   "title",            limit: 255,                 null: false
    t.string   "slug",             limit: 191,                 null: false
    t.integer  "messageboard_id",  limit: 4,                   null: false
    t.integer  "posts_count",      limit: 4,   default: 0,     null: false
    t.boolean  "sticky",                       default: false, null: false
    t.boolean  "locked",                       default: false, null: false
    t.string   "hash_id",          limit: 191,                 null: false
    t.string   "type",             limit: 191
    t.integer  "moderation_state", limit: 4,                   null: false
    t.datetime "last_post_at"
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
  end

  add_index "thredded_topics", ["hash_id"], name: "index_thredded_topics_on_hash_id", using: :btree
  add_index "thredded_topics", ["messageboard_id", "slug"], name: "index_thredded_topics_on_messageboard_id_and_slug", unique: true, using: :btree
  add_index "thredded_topics", ["messageboard_id"], name: "index_thredded_topics_on_messageboard_id", using: :btree
  add_index "thredded_topics", ["moderation_state", "sticky", "updated_at"], name: "index_thredded_topics_for_display", using: :btree
  add_index "thredded_topics", ["title"], name: "thredded_topics_title_fts", type: :fulltext
  add_index "thredded_topics", ["user_id"], name: "index_thredded_topics_on_user_id", using: :btree

  create_table "thredded_user_details", force: :cascade do |t|
    t.integer  "user_id",                     limit: 4,             null: false
    t.datetime "latest_activity_at"
    t.integer  "posts_count",                 limit: 4, default: 0
    t.integer  "topics_count",                limit: 4, default: 0
    t.datetime "last_seen_at"
    t.integer  "moderation_state",            limit: 4, default: 0, null: false
    t.datetime "moderation_state_changed_at"
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
  end

  add_index "thredded_user_details", ["latest_activity_at"], name: "index_thredded_user_details_on_latest_activity_at", using: :btree
  add_index "thredded_user_details", ["moderation_state", "moderation_state_changed_at"], name: "index_thredded_user_details_for_moderations", using: :btree
  add_index "thredded_user_details", ["user_id"], name: "index_thredded_user_details_on_user_id", using: :btree

  create_table "thredded_user_messageboard_preferences", force: :cascade do |t|
    t.integer  "user_id",                  limit: 4,                null: false
    t.integer  "messageboard_id",          limit: 4,                null: false
    t.boolean  "follow_topics_on_mention",           default: true, null: false
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
  end

  add_index "thredded_user_messageboard_preferences", ["user_id", "messageboard_id"], name: "thredded_user_messageboard_preferences_user_id_messageboard_id", unique: true, using: :btree

  create_table "thredded_user_preferences", force: :cascade do |t|
    t.integer  "user_id",                  limit: 4,                null: false
    t.boolean  "follow_topics_on_mention",           default: true, null: false
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
  end

  add_index "thredded_user_preferences", ["user_id"], name: "index_thredded_user_preferences_on_user_id", using: :btree

  create_table "thredded_user_private_topic_read_states", force: :cascade do |t|
    t.integer  "user_id",     limit: 4,             null: false
    t.integer  "postable_id", limit: 4,             null: false
    t.integer  "page",        limit: 4, default: 1, null: false
    t.datetime "read_at",                           null: false
  end

  add_index "thredded_user_private_topic_read_states", ["user_id", "postable_id"], name: "thredded_user_private_topic_read_states_user_postable", unique: true, using: :btree

  create_table "thredded_user_topic_follows", force: :cascade do |t|
    t.integer  "user_id",    limit: 4, null: false
    t.integer  "topic_id",   limit: 4, null: false
    t.datetime "created_at",           null: false
    t.integer  "reason",     limit: 1
  end

  add_index "thredded_user_topic_follows", ["user_id", "topic_id"], name: "thredded_user_topic_follows_user_topic", unique: true, using: :btree

  create_table "thredded_user_topic_read_states", force: :cascade do |t|
    t.integer  "user_id",     limit: 4,             null: false
    t.integer  "postable_id", limit: 4,             null: false
    t.integer  "page",        limit: 4, default: 1, null: false
    t.datetime "read_at",                           null: false
  end

  add_index "thredded_user_topic_read_states", ["user_id", "postable_id"], name: "thredded_user_topic_read_states_user_postable", unique: true, using: :btree

  create_table "user_messages", force: :cascade do |t|
    t.integer "user_id",            limit: 4,                   null: false
    t.integer "private_message_id", limit: 4,                   null: false
    t.string  "method",             limit: 255
    t.boolean "unread",                         default: true
    t.boolean "deleted",                        default: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                     limit: 255,   default: "",    null: false
    t.string   "encrypted_password",        limit: 255,   default: "",    null: false
    t.string   "reset_password_token",      limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",             limit: 4,     default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",        limit: 255
    t.string   "last_sign_in_ip",           limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "guest",                                   default: false
    t.string   "username",                  limit: 255
    t.string   "role",                      limit: 255
    t.boolean  "email_is_public",                         default: false
    t.text     "bio",                       limit: 65535
    t.boolean  "reviewed",                                default: false
    t.integer  "reviewed_by_id",            limit: 4
    t.datetime "reviewed_at"
    t.integer  "created_by_id",             limit: 4
    t.integer  "updated_by_id",             limit: 4
    t.string   "fullname",                  limit: 255
    t.boolean  "active",                                  default: true
    t.string   "institutional_affiliation", limit: 255
    t.integer  "bookmark_tracker",          limit: 4,     default: 0
  end

  add_index "users", ["created_by_id"], name: "index_users_on_created_by_id", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["reviewed_by_id"], name: "index_users_on_reviewed_by_id", using: :btree
  add_index "users", ["updated_by_id"], name: "index_users_on_updated_by_id", using: :btree
  add_index "users", ["username"], name: "index_users_on_username", unique: true, using: :btree

  create_table "version_associations", force: :cascade do |t|
    t.integer "version_id",       limit: 4
    t.string  "foreign_key_name", limit: 255, null: false
    t.integer "foreign_key_id",   limit: 4
  end

  add_index "version_associations", ["foreign_key_name", "foreign_key_id"], name: "index_version_associations_on_foreign_key", using: :btree
  add_index "version_associations", ["version_id"], name: "index_version_associations_on_version_id", using: :btree

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",      limit: 255,   null: false
    t.integer  "item_id",        limit: 4,     null: false
    t.string   "event",          limit: 255,   null: false
    t.string   "whodunnit",      limit: 255
    t.text     "object",         limit: 65535
    t.datetime "created_at"
    t.text     "object_changes", limit: 65535
    t.integer  "transaction_id", limit: 4
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree
  add_index "versions", ["transaction_id"], name: "index_versions_on_transaction_id", using: :btree

  create_table "watches", force: :cascade do |t|
    t.integer "watched_id",   limit: 4
    t.string  "watched_type", limit: 255
    t.integer "user_id",      limit: 4
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
