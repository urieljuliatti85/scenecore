require "rails_helper"

# Production used to be configured for Solid Queue/Cache/Cable, none of which
# had tables: config/database.yml declares a single database with no
# `queue`/`cache`/`cable` connections, so db/queue_schema.rb and friends are
# never loaded and every enqueue or cache write against them fails. These
# specs pin the two halves together, so pointing production back at a Solid
# backend without first adding the matching database connection fails here
# rather than in production.
RSpec.describe "Production background/cache backends" do
  def active_lines(matching)
    Rails.root.join("config/environments/production.rb").readlines
      .grep(matching)
      .reject { |line| line.strip.start_with?("#") }
      .join
  end

  it "declares no separate queue/cache/cable database connections" do
    connections = YAML.safe_load(Rails.root.join("config/database.yml").read, aliases: true).fetch("production")

    expect(connections.keys).not_to include("queue", "cache", "cable")
  end

  it "does not point Active Job at Solid Queue" do
    expect(active_lines(/queue_adapter/)).not_to include("solid_queue")
  end

  it "does not point the cache store at Solid Cache" do
    expect(active_lines(/cache_store/)).not_to include("solid_cache")
  end

  it "does not point Action Cable at Solid Cable" do
    cable = YAML.safe_load(Rails.root.join("config/cable.yml").read, aliases: true)

    expect(cable.fetch("production").fetch("adapter")).not_to eq("solid_cable")
  end

  # Active Storage in production writes to a Railway Volume mount, not the
  # container filesystem, which is wiped on every deploy. The `:local`
  # service roots at Rails.root/storage — inside the container — so pointing
  # production back at it silently reintroduces upload loss.
  describe "Active Storage" do
    it "uses the volume-backed production service, not :local" do
      configured = active_lines(/active_storage\.service/)

      expect(configured).to include(":production")
      expect(configured).not_to include(":local")
    end

    it "roots the production service at a configurable mount path" do
      storage = YAML.safe_load(
        ERB.new(Rails.root.join("config/storage.yml").read).result, aliases: true
      )

      expect(storage.fetch("production").fetch("service")).to eq("Disk")
    end
  end
end
