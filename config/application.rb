require_relative 'boot'
require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module App
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.autoload_paths += %W["#{config.root}/app/validators/"]
    config.assets.paths << "#{Rails.root}/app/assets/fonts"
    config.assets.precompile += %w( .svg .eot .woff .woff2 .ttf )

    config.action_mailer.default_url_options = { host: ENV['APP_HOST_URL']}
    config.active_job.queue_adapter = :sidekiq
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource %r"/schemas/.*/versions/\d+\.json",
          credentials: false, headers: :any, methods: [:get, :options]
      end
    end
  end
end
