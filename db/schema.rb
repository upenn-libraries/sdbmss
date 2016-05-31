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

ActiveRecord::Schema.define(version: 20160531184324) do

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
    t.text     "comment",        limit: 65535
    t.boolean  "public",                       default: true
    t.boolean  "is_correction",                default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "reviewed",                     default: false
    t.datetime "reviewed_at"
    t.boolean  "deleted",                      default: false
    t.integer  "created_by_id",  limit: 4
    t.integer  "updated_by_id",  limit: 4
    t.integer  "reviewed_by_id", limit: 4
    t.boolean  "is_accepted",                  default: false
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

  create_table "downloads", force: :cascade do |t|
    t.string  "filename", limit: 255
    t.integer "status",   limit: 4
    t.integer "user_id",  limit: 4
  end

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
    t.text     "comment",             limit: 65535
    t.boolean  "reviewed",                          default: false
    t.integer  "reviewed_by_id",      limit: 4
    t.datetime "reviewed_at"
    t.integer  "provenance_count",    limit: 4,     default: 0,     null: false
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
    t.text     "comments",             limit: 65535
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
  add_foreign_key "provenance", "names", column: "provenance_agent_id"
  add_foreign_key "sale_agents", "names", column: "agent_id"
  add_foreign_key "sale_agents", "sales", on_delete: :cascade
  add_foreign_key "sales", "entries", on_delete: :cascade
  add_foreign_key "sales", "users", column: "created_by_id"
  add_foreign_key "sales", "users", column: "updated_by_id"
  add_foreign_key "source_agents", "names", column: "agent_id"
  add_foreign_key "source_agents", "sources", on_delete: :cascade
  add_foreign_key "sources", "source_types"
  add_foreign_key "sources", "users", column: "created_by_id"
  add_foreign_key "sources", "users", column: "reviewed_by_id"
  add_foreign_key "sources", "users", column: "updated_by_id"
  add_foreign_key "users", "users", column: "created_by_id"
  add_foreign_key "users", "users", column: "reviewed_by_id"
  add_foreign_key "users", "users", column: "updated_by_id"
end
