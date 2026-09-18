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

ActiveRecord::Schema[8.1].define(version: 2026_09_18_000640) do
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

  create_table "band_admin_requests", force: :cascade do |t|
    t.bigint "band_id", null: false
    t.datetime "created_at", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["band_id"], name: "index_band_admin_requests_on_band_id"
    t.index ["user_id", "band_id"], name: "index_band_admin_requests_on_pending_user_and_band", unique: true, where: "((status)::text = 'pending'::text)"
    t.index ["user_id"], name: "index_band_admin_requests_on_user_id"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'approved'::character varying, 'rejected'::character varying, 'revoked'::character varying]::text[])", name: "band_admin_requests_status_check"
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
    t.string "country_code", default: "BR", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "featured", default: false, null: false
    t.string "instagram_url"
    t.string "name", null: false
    t.string "slug", null: false
    t.string "spotify_url"
    t.string "status", default: "pending", null: false
    t.string "stripe_connect_account_id"
    t.string "stripe_connect_status", default: "not_started", null: false
    t.datetime "updated_at", null: false
    t.string "website_url"
    t.string "youtube_url"
    t.index ["category_id"], name: "index_bands_on_category_id"
    t.index ["featured"], name: "index_bands_on_featured", unique: true, where: "(featured = true)"
    t.index ["slug"], name: "index_bands_on_slug", unique: true
    t.index ["status"], name: "index_bands_on_status"
    t.index ["stripe_connect_account_id"], name: "index_bands_on_stripe_connect_account_id", unique: true
    t.check_constraint "country_code::text ~ '^[A-Z]{2}$'::text", name: "bands_country_code_check"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'approved'::character varying, 'rejected'::character varying, 'suspended'::character varying]::text[])", name: "bands_status_check"
    t.check_constraint "stripe_connect_status::text = ANY (ARRAY['not_started'::character varying, 'onboarding'::character varying, 'active'::character varying, 'restricted'::character varying]::text[])", name: "bands_stripe_connect_status_check"
  end

  create_table "cart_items", force: :cascade do |t|
    t.bigint "cart_id", null: false
    t.datetime "created_at", null: false
    t.bigint "product_variant_id", null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["cart_id", "product_variant_id"], name: "index_cart_items_on_cart_id_and_product_variant_id", unique: true
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["product_variant_id"], name: "index_cart_items_on_product_variant_id"
    t.check_constraint "quantity > 0", name: "cart_items_quantity_check"
  end

  create_table "carts", force: :cascade do |t|
    t.bigint "band_id", null: false
    t.datetime "created_at", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["band_id"], name: "index_carts_on_band_id"
    t.index ["user_id"], name: "index_carts_on_user_id"
    t.index ["user_id"], name: "index_carts_on_user_id_when_active", unique: true, where: "((status)::text = 'active'::text)"
    t.check_constraint "status::text = ANY (ARRAY['active'::character varying, 'converted'::character varying, 'abandoned'::character varying]::text[])", name: "carts_status_check"
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

  create_table "order_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "order_id", null: false
    t.string "product_name", null: false
    t.bigint "product_variant_id"
    t.integer "quantity", null: false
    t.integer "unit_price_cents", null: false
    t.datetime "updated_at", null: false
    t.string "variant_name", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_variant_id"], name: "index_order_items_on_product_variant_id"
    t.check_constraint "quantity > 0", name: "order_items_quantity_check"
    t.check_constraint "unit_price_cents >= 0", name: "order_items_unit_price_cents_check"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "band_id", null: false
    t.datetime "created_at", null: false
    t.integer "platform_fee_cents", null: false
    t.integer "shipping_cents", default: 0, null: false
    t.string "status", default: "pending", null: false
    t.string "stripe_checkout_session_id"
    t.integer "subtotal_cents", null: false
    t.integer "total_cents", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["band_id"], name: "index_orders_on_band_id"
    t.index ["stripe_checkout_session_id"], name: "index_orders_on_stripe_checkout_session_id", unique: true
    t.index ["user_id"], name: "index_orders_on_user_id"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'paid'::character varying, 'processing'::character varying, 'completed'::character varying, 'cancelled'::character varying, 'refunded'::character varying]::text[])", name: "orders_status_check"
    t.check_constraint "subtotal_cents >= 0 AND shipping_cents >= 0 AND total_cents >= 0 AND platform_fee_cents >= 0", name: "orders_amounts_non_negative_check"
  end

  create_table "platform_settings", force: :cascade do |t|
    t.boolean "band_signups_enabled", default: true, null: false
    t.datetime "created_at", null: false
    t.integer "membership_fee_percentage", default: 15, null: false
    t.string "notification_sender_email"
    t.string "privacy_policy_url"
    t.integer "store_fee_percentage", default: 10, null: false
    t.string "support_email"
    t.string "terms_of_service_url"
    t.datetime "updated_at", null: false
    t.check_constraint "membership_fee_percentage >= 0 AND membership_fee_percentage <= 100", name: "platform_settings_membership_fee_range_check"
    t.check_constraint "store_fee_percentage >= 0 AND store_fee_percentage <= 100", name: "platform_settings_store_fee_range_check"
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
    t.check_constraint "post_type::text = ANY (ARRAY['announcement'::character varying, 'composition_journal'::character varying, 'rehearsal_recording'::character varying]::text[])", name: "posts_post_type_check"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying, 'published'::character varying]::text[])", name: "posts_status_check"
    t.check_constraint "visibility::text = ANY (ARRAY['public'::character varying, 'followers'::character varying, 'fan'::character varying, 'supporter'::character varying, 'core_member'::character varying]::text[])", name: "posts_visibility_check"
  end

  create_table "product_shipping_rates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "product_id", null: false
    t.integer "shipping_cents", null: false
    t.bigint "shipping_zone_id", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "shipping_zone_id"], name: "idx_on_product_id_shipping_zone_id_1f0dc9b69f", unique: true
    t.index ["product_id"], name: "index_product_shipping_rates_on_product_id"
    t.index ["shipping_zone_id"], name: "index_product_shipping_rates_on_shipping_zone_id"
    t.check_constraint "shipping_cents >= 0", name: "product_shipping_rates_shipping_cents_non_negative"
  end

  create_table "product_variants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "price_cents", null: false
    t.bigint "product_id", null: false
    t.string "sku", null: false
    t.integer "stock_quantity", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_product_variants_on_product_id"
    t.index ["sku"], name: "index_product_variants_on_sku", unique: true
    t.check_constraint "price_cents >= 0", name: "product_variants_price_cents_check"
    t.check_constraint "stock_quantity >= 0", name: "product_variants_stock_quantity_check"
  end

  create_table "products", force: :cascade do |t|
    t.string "artist_name"
    t.bigint "band_id", null: false
    t.string "barcode"
    t.string "catalog_number"
    t.datetime "created_at", null: false
    t.text "description"
    t.jsonb "discogs_metadata", default: {}, null: false
    t.bigint "discogs_release_id"
    t.datetime "discogs_synced_at"
    t.string "label_name"
    t.string "name", null: false
    t.string "release_format"
    t.integer "release_year"
    t.integer "shipping_cents", default: 0, null: false
    t.string "source", default: "manual", null: false
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.index ["band_id", "discogs_release_id"], name: "index_products_on_band_and_discogs_release", unique: true, where: "(discogs_release_id IS NOT NULL)"
    t.index ["band_id"], name: "index_products_on_band_id"
    t.check_constraint "shipping_cents >= 0", name: "products_shipping_cents_check"
    t.check_constraint "source::text = ANY (ARRAY['manual'::character varying, 'discogs'::character varying]::text[])", name: "products_source_check"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying, 'published'::character varying]::text[])", name: "products_status_check"
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

  create_table "shipping_addresses", force: :cascade do |t|
    t.string "city", null: false
    t.string "country", null: false
    t.datetime "created_at", null: false
    t.string "line1", null: false
    t.string "line2"
    t.bigint "order_id", null: false
    t.string "postal_code", null: false
    t.string "recipient_name", null: false
    t.string "state", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_shipping_addresses_on_order_id", unique: true
  end

  create_table "shipping_zone_countries", force: :cascade do |t|
    t.bigint "band_id", null: false
    t.string "country_code", null: false
    t.datetime "created_at", null: false
    t.bigint "shipping_zone_id", null: false
    t.datetime "updated_at", null: false
    t.index ["band_id", "country_code"], name: "index_shipping_zone_countries_on_band_id_and_country_code", unique: true
    t.index ["band_id"], name: "index_shipping_zone_countries_on_band_id"
    t.index ["shipping_zone_id"], name: "index_shipping_zone_countries_on_shipping_zone_id"
    t.check_constraint "country_code::text ~ '^[A-Z]{2}$'::text", name: "shipping_zone_countries_country_code_iso"
  end

  create_table "shipping_zones", force: :cascade do |t|
    t.bigint "band_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.integer "shipping_cents", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["band_id", "name"], name: "index_shipping_zones_on_band_id_and_name", unique: true
    t.index ["band_id"], name: "index_shipping_zones_on_band_id"
    t.check_constraint "shipping_cents >= 0", name: "shipping_zones_shipping_cents_non_negative"
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
  add_foreign_key "band_admin_requests", "bands"
  add_foreign_key "band_admin_requests", "users"
  add_foreign_key "band_membership_prices", "bands"
  add_foreign_key "band_memberships", "bands"
  add_foreign_key "band_memberships", "users"
  add_foreign_key "bands", "categories"
  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "product_variants"
  add_foreign_key "carts", "bands"
  add_foreign_key "carts", "users"
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
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "product_variants", on_delete: :nullify
  add_foreign_key "orders", "bands"
  add_foreign_key "orders", "users"
  add_foreign_key "poll_options", "polls"
  add_foreign_key "poll_votes", "poll_options"
  add_foreign_key "poll_votes", "users"
  add_foreign_key "polls", "bands"
  add_foreign_key "posts", "bands"
  add_foreign_key "product_shipping_rates", "products"
  add_foreign_key "product_shipping_rates", "shipping_zones"
  add_foreign_key "product_variants", "products"
  add_foreign_key "products", "bands"
  add_foreign_key "ratings", "albums"
  add_foreign_key "ratings", "users"
  add_foreign_key "reports", "users", column: "reporter_id"
  add_foreign_key "shipping_addresses", "orders"
  add_foreign_key "shipping_zone_countries", "bands"
  add_foreign_key "shipping_zone_countries", "shipping_zones"
  add_foreign_key "shipping_zones", "bands"
  add_foreign_key "subscriptions", "bands"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "tracks", "albums"
end
