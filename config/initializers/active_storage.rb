# Draws the engine's routes manually in config/routes.rb instead, so the
# public blob redirect route (Rails' default is publicly accessible to
# anyone who has the URL, forever) can be replaced with one that checks
# the attachment's owning record is actually visible to the current
# viewer. See AuthenticatedBlobsController.
Rails.application.config.active_storage.draw_routes = false
