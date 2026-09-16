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

ActiveRecord::Schema[8.1].define(version: 2026_09_16_142538) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_action_logs", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "actor_id", null: false
    t.datetime "created_at", null: false
    t.bigint "subject_id", null: false
    t.string "subject_type", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_admin_action_logs_on_actor_id"
    t.index ["subject_type", "subject_id"], name: "index_admin_action_logs_on_subject"
  end

  create_table "albums", force: :cascade do |t|
    t.bigint "band_id", null: false
    t.datetime "created_at", null: false
    t.string "spotify_cover_url"
    t.string "spotify_id"
    t.string "status", default: "draft", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["band_id", "status"], name: "index_albums_on_band_id_and_status"
    t.index ["band_id"], name: "index_albums_on_band_id"
    t.index ["spotify_id"], name: "index_albums_on_spotify_id"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying, 'published'::character varying]::text[])", name: "albums_status_check"
  end

  create_table "band_memberships", force: :cascade do |t|
    t.bigint "band_id", null: false
    t.datetime "created_at", null: false
    t.string "role", default: "member", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["band_id", "role"], name: "index_band_memberships_on_band_id_and_role"
    t.index ["band_id"], name: "index_band_memberships_on_band_id"
    t.index ["user_id", "band_id"], name: "index_band_memberships_on_user_id_and_band_id", unique: true
    t.index ["user_id"], name: "index_band_memberships_on_user_id"
    t.check_constraint "role::text = ANY (ARRAY['member'::character varying, 'administrator'::character varying]::text[])", name: "band_memberships_role_check"
  end

  create_table "bands", force: :cascade do |t|
    t.string "bandcamp_url"
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "instagram_url"
    t.string "name", null: false
    t.string "slug", null: false
    t.string "spotify_url"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.string "website_url"
    t.string "youtube_url"
    t.index ["category_id"], name: "index_bands_on_category_id"
    t.index ["slug"], name: "index_bands_on_slug", unique: true
    t.index ["status"], name: "index_bands_on_status"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'approved'::character varying, 'rejected'::character varying, 'suspended'::character varying]::text[])", name: "bands_status_check"
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "parent_id"
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_categories_on_parent_id"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "contact_messages", force: :cascade do |t|
    t.string "band"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.text "message", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_contact_messages_on_created_at"
  end

  create_table "events", force: :cascade do |t|
    t.bigint "band_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "location", null: false
    t.datetime "starts_at", null: false
    t.string "status", default: "draft", null: false
    t.string "ticket_url"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["band_id", "status", "starts_at"], name: "index_events_on_band_id_and_status_and_starts_at"
    t.index ["band_id"], name: "index_events_on_band_id"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying, 'published'::character varying]::text[])", name: "events_status_check"
  end

  create_table "follows", force: :cascade do |t|
    t.bigint "band_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["band_id"], name: "index_follows_on_band_id"
    t.index ["user_id", "band_id"], name: "index_follows_on_user_id_and_band_id", unique: true
    t.index ["user_id"], name: "index_follows_on_user_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.bigint "band_id", null: false
    t.datetime "created_at", null: false
    t.string "level", default: "fan", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["band_id", "level"], name: "index_memberships_on_band_id_and_level"
    t.index ["band_id", "status"], name: "index_memberships_on_band_id_and_status"
    t.index ["band_id"], name: "index_memberships_on_band_id"
    t.index ["user_id", "band_id"], name: "index_memberships_on_user_id_and_band_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
    t.check_constraint "level::text = ANY (ARRAY['fan'::character varying, 'supporter'::character varying, 'core_member'::character varying]::text[])", name: "memberships_level_check"
    t.check_constraint "status::text = ANY (ARRAY['active'::character varying, 'paused'::character varying, 'cancelled'::character varying, 'expired'::character varying]::text[])", name: "memberships_status_check"
  end

  create_table "posts", force: :cascade do |t|
    t.bigint "band_id", null: false
    t.datetime "created_at", null: false
    t.string "status", default: "draft", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "visibility", default: "public", null: false
    t.index ["band_id", "status", "visibility"], name: "index_posts_on_band_id_and_status_and_visibility"
    t.index ["band_id"], name: "index_posts_on_band_id"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying, 'published'::character varying]::text[])", name: "posts_status_check"
    t.check_constraint "visibility::text = ANY (ARRAY['public'::character varying, 'followers'::character varying, 'subscribers'::character varying]::text[])", name: "posts_visibility_check"
  end

  create_table "ratings", force: :cascade do |t|
    t.bigint "album_id", null: false
    t.datetime "created_at", null: false
    t.integer "score", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["album_id", "score"], name: "index_ratings_on_album_id_and_score"
    t.index ["album_id"], name: "index_ratings_on_album_id"
    t.index ["user_id", "album_id"], name: "index_ratings_on_user_id_and_album_id", unique: true
    t.index ["user_id"], name: "index_ratings_on_user_id"
    t.check_constraint "score >= 1 AND score <= 5", name: "ratings_score_check"
  end

  create_table "tracks", force: :cascade do |t|
    t.bigint "album_id", null: false
    t.datetime "created_at", null: false
    t.string "spotify_url"
    t.string "status", default: "draft", null: false
    t.string "title", null: false
    t.integer "track_number", null: false
    t.datetime "updated_at", null: false
    t.index ["album_id", "status"], name: "index_tracks_on_album_id_and_status"
    t.index ["album_id"], name: "index_tracks_on_album_id"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying, 'published'::character varying]::text[])", name: "tracks_status_check"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", null: false
    t.boolean "platform_admin", default: false, null: false
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "admin_action_logs", "users", column: "actor_id"
  add_foreign_key "albums", "bands"
  add_foreign_key "band_memberships", "bands"
  add_foreign_key "band_memberships", "users"
  add_foreign_key "bands", "categories"
  add_foreign_key "categories", "categories", column: "parent_id"
  add_foreign_key "events", "bands"
  add_foreign_key "follows", "bands"
  add_foreign_key "follows", "users"
  add_foreign_key "memberships", "bands"
  add_foreign_key "memberships", "users"
  add_foreign_key "posts", "bands"
  add_foreign_key "ratings", "albums"
  add_foreign_key "ratings", "users"
  add_foreign_key "tracks", "albums"
end
