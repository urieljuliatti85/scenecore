# Development demo data. Keep this idempotent so `bin/rails db:seed` can be
# safely run again without duplicating records.
if Rails.env.development?
  password = ENV.fetch("SEED_PASSWORD", "password123")

  upsert_user = lambda do |email:, name:, platform_admin: false|
    user = User.find_or_initialize_by(email: email)
    user.assign_attributes(name: name, platform_admin: platform_admin)
    user.password = password if user.new_record?
    user.save!
    user
  end

  platform_admin = upsert_user.call(
    email: "admin@scenecore.local",
    name: "SceneCore Admin",
    platform_admin: true
  )

  farscape = Band.find_or_initialize_by(name: "Farscape")
  farscape.assign_attributes(
    description: "Farscape on SceneCore.",
    country_code: "BR",
    spotify_url: "https://open.spotify.com/artist/75NkIB7RrU03OGE4UkqPTo",
    status: :approved
  )
  farscape.save!

  AdminActionLog.find_or_create_by!(
    actor: platform_admin,
    action: "approve_band",
    subject: farscape
  )

  seeded_members = {
    fan: upsert_user.call(email: "fan@scenecore.local", name: "Farscape Fan"),
    supporter: upsert_user.call(email: "supporter@scenecore.local", name: "Farscape Supporter"),
    core_member: upsert_user.call(email: "core-member@scenecore.local", name: "Farscape Core Member")
  }

  seeded_members.each do |level, user|
    membership = Membership.find_or_initialize_by(user: user, band: farscape)
    membership.assign_attributes(level: level, status: :active)
    membership.save!
  end

  fan_post = Post.find_or_initialize_by(band: farscape, title: "Bem-vindos, fãs do Farscape")
  fan_post.assign_attributes(
    body: "Este post pode ser visto por Fans, Supporters e Core Members.",
    status: :published,
    visibility: :fan,
    post_type: :announcement
  )
  fan_post.save!

  %i[supporter core_member].each do |level|
    next if fan_post.visible_to?(seeded_members.fetch(level))

    raise "Seed access check failed: #{level} cannot see the Fan post"
  end

  puts "Development seed created successfully."
  puts "Password for all seeded users: #{password}"
  puts "Supporter and Core Member access to the Fan post: verified"
else
  puts "Development demo seed skipped in #{Rails.env}."
end
#   end
