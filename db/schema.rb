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

ActiveRecord::Schema[8.1].define(version: 2026_09_17_063503) do
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

  create_table "album_credits", force: :cascade do |t|
    t.bigint "album_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["album_id", "user_id"], name: "index_album_credits_on_album_id_and_user_id", unique: true
    t.index ["album_id"], name: "index_album_credits_on_album_id"
    t.index ["user_id"], name: "index_album_credits_on_user_id"
  end

  create_table "albums", force: :cascade do |t|
    t.bigint "band_id", null: false
    t.string "bandcamp_embed_url"
    t.datetime "created_at", null: false
    t.string "early_access_level"
    t.datetime "early_access_until"
    t.string "spotify_cover_url"
    t.string "spotify_id"
    t.string "status", default: "draft", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["band_id", "status"], name: "index_albums_on_band_id_and_status"
    t.index ["band_id"], name: "index_albums_on_band_id"
    t.index ["spotify_id"], name: "index_albums_on_spotify_id"
    t.check_constraint "early_access_level IS NULL OR (early_access_level::text = ANY (ARRAY['fan'::character varying, 'supporter'::character varying, 'core_member'::character varying]::text[]))", name: "albums_early_access_level_check"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying, 'published'::character varying]::text[])", name: "albums_status_check"
  end

  create_table "band_membership_prices", force: :cascade do |t|
    t.bigint "band_id", null: false
    t.datetime "created_at", null: false
    t.string "level", null: false
    t.string "stripe_price_id", null: false
    t.string "stripe_product_id", null: false
    t.datetime "updated_at", null: false
    t.index ["band_id", "level"], name: "index_band_membership_prices_on_band_id_and_level", unique: true
    t.index ["band_id"], name: "index_band_membership_prices_on_band_id"
    t.check_constraint "level::text = ANY (ARRAY['fan'::character varying, 'supporter'::character varying, 'core_member'::character varying]::text[])", name: "band_membership_prices_level_check"
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

  create_table "comments", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.bigint "post_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["post_id"], name: "index_comments_on_post_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
    t.check_constraint "char_length(body) > 0", name: "comments_body_not_blank"
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

  create_table "core_session_rsvps", force: :cascade do |t|
    t.bigint "core_session_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["core_session_id", "user_id"], name: "index_core_session_rsvps_on_core_session_id_and_user_id", unique: true
    t.index ["core_session_id"], name: "index_core_session_rsvps_on_core_session_id"
    t.index ["user_id"], name: "index_core_session_rsvps_on_user_id"
  end

  create_table "core_sessions", force: :cascade do |t|
    t.bigint "band_id", null: false
    t.integer "capacity"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "session_type", null: false
    t.datetime "starts_at", null: false
    t.string "status", default: "draft", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["band_id"], name: "index_core_sessions_on_band_id"
    t.check_constraint "capacity IS NULL OR capacity > 0", name: "core_sessions_capacity_check"
    t.check_constraint "session_type::text = ANY (ARRAY['video'::character varying, 'audio'::character varying, 'qa'::character varying, 'listening_party'::character varying, 'meet_greet'::character varying]::text[])", name: "core_sessions_session_type_check"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying, 'published'::character varying]::text[])", name: "core_sessions_status_check"
  end

  create_table "direct_message_threads", force: :cascade do |t|
    t.bigint "band_id", null: false
    t.datetime "created_at", null: false
    t.string "status", default: "open", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["band_id", "user_id"], name: "index_direct_message_threads_on_band_id_and_user_id", unique: true
    t.index ["band_id"], name: "index_direct_message_threads_on_band_id"
    t.index ["user_id"], name: "index_direct_message_threads_on_user_id"
    t.check_constraint "status::text = ANY (ARRAY['open'::character varying, 'archived'::character varying, 'blocked'::character varying]::text[])", name: "direct_message_threads_status_check"
  end

  create_table "direct_messages", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.bigint "direct_message_thread_id", null: false
    t.boolean "sent_by_band", default: false, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["direct_message_thread_id"], name: "index_direct_messages_on_direct_message_thread_id"
    t.index ["user_id"], name: "index_direct_messages_on_user_id"
    t.check_constraint "char_length(body) > 0 AND char_length(body) <= 2000", name: "direct_messages_body_length_check"
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

  create_table "merch_discounts", force: :cascade do |t|
    t.bigint "band_id", null: false
    t.datetime "created_at", null: false
    t.string "level", null: false
    t.integer "percentage", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["band_id", "level"], name: "index_merch_discounts_on_band_id_and_level", unique: true
    t.index ["band_id"], name: "index_merch_discounts_on_band_id"
    t.check_constraint "level::text = ANY (ARRAY['fan'::character varying, 'supporter'::character varying, 'core_member'::character varying]::text[])", name: "merch_discounts_level_check"
    t.check_constraint "percentage >= 0 AND percentage <= 100", name: "merch_discounts_percentage_range_check"
  end

  create_table "poll_options", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "label", null: false
    t.bigint "poll_id", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["poll_id", "position"], name: "index_poll_options_on_poll_id_and_position"
    t.index ["poll_id"], name: "index_poll_options_on_poll_id"
  end

  create_table "poll_votes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "poll_option_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["poll_option_id"], name: "index_poll_votes_on_poll_option_id"
    t.index ["user_id", "poll_option_id"], name: "index_poll_votes_on_user_id_and_poll_option_id", unique: true
    t.index ["user_id"], name: "index_poll_votes_on_user_id"
  end

  create_table "polls", force: :cascade do |t|
    t.boolean "allow_multiple_choices", default: false, null: false
    t.boolean "allow_vote_change", default: false, null: false
    t.bigint "band_id", null: false
    t.datetime "closes_at"
    t.datetime "created_at", null: false
    t.datetime "opens_at"
    t.string "question", null: false
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.string "visibility", default: "public", null: false
    t.index ["band_id", "status"], name: "index_polls_on_band_id_and_status"
    t.index ["band_id"], name: "index_polls_on_band_id"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying, 'published'::character varying]::text[])", name: "polls_status_check"
    t.check_constraint "visibility::text = ANY (ARRAY['public'::character varying, 'followers'::character varying, 'fan'::character varying, 'supporter'::character varying, 'core_member'::character varying]::text[])", name: "polls_visibility_check"
  end

  create_table "posts", force: :cascade do |t|
    t.bigint "band_id", null: false
    t.datetime "created_at", null: false
    t.string "early_access_level"
    t.datetime "early_access_until"
    t.string "post_type", default: "announcement", null: false
    t.string "status", default: "draft", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "visibility", default: "public", null: false
    t.index ["band_id", "status", "visibility"], name: "index_posts_on_band_id_and_status_and_visibility"
    t.index ["band_id"], name: "index_posts_on_band_id"
    t.check_constraint "early_access_level IS NULL OR (early_access_level::text = ANY (ARRAY['fan'::character varying, 'supporter'::character varying, 'core_member'::character varying]::text[]))", name: "posts_early_access_level_check"
    t.check_constraint "post_type::text = ANY (ARRAY['announcement'::character varying, 'composition_journal'::character varying]::text[])", name: "posts_post_type_check"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying, 'published'::character varying]::text[])", name: "posts_status_check"
    t.check_constraint "visibility::text = ANY (ARRAY['public'::character varying, 'followers'::character varying, 'fan'::character varying, 'supporter'::character varying, 'core_member'::character varying]::text[])", name: "posts_visibility_check"
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

  create_table "reports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "reason", null: false
    t.bigint "reportable_id", null: false
    t.string "reportable_type", null: false
    t.bigint "reporter_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["reportable_type", "reportable_id"], name: "index_reports_on_reportable"
    t.index ["reporter_id"], name: "index_reports_on_reporter_id"
    t.check_constraint "char_length(reason) > 0", name: "reports_reason_not_blank"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'resolved'::character varying, 'dismissed'::character varying]::text[])", name: "reports_status_check"
  end

  create_table "stripe_webhook_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.datetime "processed_at"
    t.string "stripe_event_id", null: false
    t.datetime "updated_at", null: false
    t.index ["stripe_event_id"], name: "index_stripe_webhook_events_on_stripe_event_id", unique: true
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "band_id", null: false
    t.datetime "created_at", null: false
    t.string "level", null: false
    t.string "status", default: "pending", null: false
    t.string "stripe_checkout_session_id"
    t.string "stripe_customer_id", null: false
    t.string "stripe_subscription_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["band_id"], name: "index_subscriptions_on_band_id"
    t.index ["stripe_checkout_session_id"], name: "index_subscriptions_on_stripe_checkout_session_id", unique: true
    t.index ["stripe_subscription_id"], name: "index_subscriptions_on_stripe_subscription_id", unique: true
    t.index ["user_id", "band_id"], name: "index_subscriptions_on_user_id_and_band_id", unique: true
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
    t.check_constraint "level::text = ANY (ARRAY['fan'::character varying, 'supporter'::character varying, 'core_member'::character varying]::text[])", name: "subscriptions_level_check"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'active'::character varying, 'past_due'::character varying, 'cancelled'::character varying, 'expired'::character varying]::text[])", name: "subscriptions_status_check"
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
    t.string "stripe_customer_id"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["stripe_customer_id"], name: "index_users_on_stripe_customer_id", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "admin_action_logs", "users", column: "actor_id"
  add_foreign_key "album_credits", "albums"
  add_foreign_key "album_credits", "users"
  add_foreign_key "albums", "bands"
  add_foreign_key "band_membership_prices", "bands"
  add_foreign_key "band_memberships", "bands"
  add_foreign_key "band_memberships", "users"
  add_foreign_key "bands", "categories"
  add_foreign_key "categories", "categories", column: "parent_id"
  add_foreign_key "comments", "posts"
  add_foreign_key "comments", "users"
  add_foreign_key "core_session_rsvps", "core_sessions"
  add_foreign_key "core_session_rsvps", "users"
  add_foreign_key "core_sessions", "bands"
  add_foreign_key "direct_message_threads", "bands"
  add_foreign_key "direct_message_threads", "users"
  add_foreign_key "direct_messages", "direct_message_threads"
  add_foreign_key "direct_messages", "users"
  add_foreign_key "events", "bands"
  add_foreign_key "follows", "bands"
  add_foreign_key "follows", "users"
  add_foreign_key "memberships", "bands"
  add_foreign_key "memberships", "users"
  add_foreign_key "merch_discounts", "bands"
  add_foreign_key "poll_options", "polls"
  add_foreign_key "poll_votes", "poll_options"
  add_foreign_key "poll_votes", "users"
  add_foreign_key "polls", "bands"
  add_foreign_key "posts", "bands"
  add_foreign_key "ratings", "albums"
  add_foreign_key "ratings", "users"
  add_foreign_key "reports", "users", column: "reporter_id"
  add_foreign_key "subscriptions", "bands"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "tracks", "albums"
end
