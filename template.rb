# Rails Boilerplate Template
# Usage: rails new myapp --database=postgresql --template=template.rb

def source_paths
  [__dir__]
end

# ============================================================
# Gems
# ============================================================

# Auth
gem "authentication-zero"

# Background jobs
gem "sidekiq"

# File storage
gem "aws-sdk-s3", require: false

# Payments
gem "pay"
gem "stripe"

# Multi-tenancy
gem "acts_as_tenant"

# Feature flags
gem "flipper"
gem "flipper-active_record"
gem "flipper-ui"

# Audit logging
gem "paper_trail"

# Error tracking
gem "sentry-ruby"
gem "sentry-rails"
gem "sentry-sidekiq"

# Ankane gems
gem "strong_migrations"
gem "pretender"
gem "ahoy_matey"
gem "pghero"
gem "groupdate"
gem "lockbox"
gem "blind_index"

gem_group :development, :test do
  gem "dotenv-rails"
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "standard"
  gem "brakeman", require: false
end

gem_group :development do
  gem "letter_opener"
end

gem_group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "shoulda-matchers"
end

# ============================================================
# After bundle
# ============================================================

after_bundle do

  # --------------------------------------------------------
  # Remove default test framework
  # --------------------------------------------------------
  remove_dir "test"

  # --------------------------------------------------------
  # .env files
  # --------------------------------------------------------
  create_file ".env" do
    <<~ENV
      # Local environment variables — never commit this file
      DATABASE_URL=postgresql://localhost/#{app_name}_development

      # Sentry
      SENTRY_DSN=

      # Stripe
      STRIPE_PUBLIC_KEY=
      STRIPE_PRIVATE_KEY=
      STRIPE_SIGNING_SECRET=

      # AWS / Active Storage
      AWS_ACCESS_KEY_ID=
      AWS_SECRET_ACCESS_KEY=
      AWS_BUCKET=
      AWS_REGION=us-east-1

      # Encryption (generate with: bin/rails db:encryption:init)
      LOCKBOX_MASTER_KEY=
    ENV
  end

  create_file ".env.example" do
    <<~ENV
      DATABASE_URL=postgresql://localhost/#{app_name}_development

      SENTRY_DSN=
      STRIPE_PUBLIC_KEY=
      STRIPE_PRIVATE_KEY=
      STRIPE_SIGNING_SECRET=

      AWS_ACCESS_KEY_ID=
      AWS_SECRET_ACCESS_KEY=
      AWS_BUCKET=
      AWS_REGION=us-east-1

      LOCKBOX_MASTER_KEY=
    ENV
  end

  append_to_file ".gitignore", "\n.env\n"

  # --------------------------------------------------------
  # RSpec
  # --------------------------------------------------------
  generate "rspec:install"

  append_to_file ".rspec", "--format documentation\n"

  inject_into_file "spec/rails_helper.rb", after: "RSpec.configure do |config|\n" do
    <<~RUBY
      config.include FactoryBot::Syntax::Methods

      config.before(:suite) do
        DatabaseCleaner.strategy = :transaction
        DatabaseCleaner.clean_with(:truncation)
      end

      config.around(:each) do |example|
        DatabaseCleaner.cleaning { example.run }
      end

    RUBY
  end

  # --------------------------------------------------------
  # StandardRB
  # --------------------------------------------------------
  create_file ".standard.yml", "ruby_version: 3.3\n"

  # --------------------------------------------------------
  # Authentication
  # --------------------------------------------------------
  generate "authentication"

  # --------------------------------------------------------
  # Sidekiq
  # --------------------------------------------------------
  environment "config.active_job.queue_adapter = :sidekiq"

  create_file "config/sidekiq.yml" do
    <<~YAML
      :concurrency: 5
      :queues:
        - default
        - mailers
        - active_storage_analysis
        - active_storage_purge
    YAML
  end

  route <<~RUBY
    require "sidekiq/web"

    authenticate :user, ->(u) { u.admin? } do
      mount Sidekiq::Web => "/sidekiq"
    end
  RUBY

  # --------------------------------------------------------
  # Action Mailer
  # --------------------------------------------------------
  environment 'config.action_mailer.delivery_method = :letter_opener', env: "development"
  environment 'config.action_mailer.perform_deliveries = true', env: "development"

  # --------------------------------------------------------
  # Active Storage — S3
  # --------------------------------------------------------
  gsub_file "config/storage.yml", /^amazon:\n.*\n.*\n.*\n.*\n/m do
    <<~YAML
      amazon:
        service: S3
        access_key_id: <%= ENV["AWS_ACCESS_KEY_ID"] %>
        secret_access_key: <%= ENV["AWS_SECRET_ACCESS_KEY"] %>
        region: <%= ENV["AWS_REGION"] %>
        bucket: <%= ENV["AWS_BUCKET"] %>
    YAML
  end

  environment 'config.active_storage.service = :amazon', env: "production"

  # --------------------------------------------------------
  # Sentry
  # --------------------------------------------------------
  create_file "config/initializers/sentry.rb" do
    <<~RUBY
      Sentry.init do |config|
        config.dsn = ENV["SENTRY_DSN"]
        config.breadcrumbs_logger = [:active_support_logger, :http_logger]
        config.traces_sample_rate = 0.2
        config.profiles_sample_rate = 0.2
        config.enabled_environments = %w[production staging]
      end
    RUBY
  end

  # --------------------------------------------------------
  # Lockbox
  # --------------------------------------------------------
  create_file "config/initializers/lockbox.rb" do
    <<~RUBY
      Lockbox.master_key = ENV["LOCKBOX_MASTER_KEY"]
    RUBY
  end

  # --------------------------------------------------------
  # Ahoy (analytics)
  # --------------------------------------------------------
  generate "ahoy:install"

  # --------------------------------------------------------
  # PgHero
  # --------------------------------------------------------
  generate "pghero:query_stats"
  generate "pghero:space_stats"

  route <<~RUBY
    authenticate :user, ->(u) { u.admin? } do
      mount PgHero::Engine => "/pghero"
    end
  RUBY

  # --------------------------------------------------------
  # Pay (billing)
  # --------------------------------------------------------
  generate "pay:install"

  # --------------------------------------------------------
  # Flipper (feature flags)
  # --------------------------------------------------------
  generate "flipper:active_record"

  route <<~RUBY
    authenticate :user, ->(u) { u.admin? } do
      mount Flipper::UI.app(Flipper) => "/flipper"
    end
  RUBY

  # --------------------------------------------------------
  # Paper Trail (audit log)
  # --------------------------------------------------------
  generate "paper_trail:install"

  # --------------------------------------------------------
  # Pretender (user impersonation)
  # --------------------------------------------------------
  inject_into_file "app/controllers/application_controller.rb", after: "class ApplicationController < ActionController::Base\n" do
    <<~RUBY
      include Pretender

      impersonates :user
    RUBY
  end

  # --------------------------------------------------------
  # Brakeman
  # --------------------------------------------------------
  create_file "config/brakeman.ignore" do
    <<~JSON
      {
        "ignored_warnings": []
      }
    JSON
  end

  # --------------------------------------------------------
  # Strong Migrations
  # --------------------------------------------------------
  generate "strong_migrations:install"

  # --------------------------------------------------------
  # acts_as_tenant
  # --------------------------------------------------------
  # Intentionally not auto-configured — tenant model varies per app.
  # Add `acts_as_tenant :account` to models and
  # `set_current_tenant_by_subdomain` or `set_current_tenant_through_filter`
  # to ApplicationController when ready.

  # --------------------------------------------------------
  # GitHub Actions CI
  # --------------------------------------------------------
  FileUtils.mkdir_p ".github/workflows"

  create_file ".github/workflows/ci.yml" do
    <<~YAML
      name: CI

      on:
        push:
          branches: [main]
        pull_request:
          branches: [main]

      jobs:
        test:
          runs-on: ubuntu-latest

          services:
            postgres:
              image: postgres:16
              env:
                POSTGRES_USER: postgres
                POSTGRES_PASSWORD: postgres
              ports: ["5432:5432"]
              options: >-
                --health-cmd pg_isready
                --health-interval 10s
                --health-timeout 5s
                --health-retries 5

            redis:
              image: redis:7
              ports: ["6379:6379"]
              options: >-
                --health-cmd "redis-cli ping"
                --health-interval 10s
                --health-timeout 5s
                --health-retries 5

          env:
            RAILS_ENV: test
            DATABASE_URL: postgresql://postgres:postgres@localhost/#{app_name}_test
            LOCKBOX_MASTER_KEY: "#{"0" * 64}"

          steps:
            - uses: actions/checkout@v4

            - name: Set up Ruby
              uses: ruby/setup-ruby@v1
              with:
                bundler-cache: true

            - name: Set up database
              run: bin/rails db:create db:schema:load

            - name: Run tests
              run: bundle exec rspec

            - name: Lint
              run: bundle exec standardrb

            - name: Security scan
              run: bundle exec brakeman --no-pager
    YAML
  end

  # --------------------------------------------------------
  # Database setup & migrations
  # --------------------------------------------------------
  rails_command "db:create"
  rails_command "db:migrate"

  # --------------------------------------------------------
  # Done
  # --------------------------------------------------------
  say "\n\n"
  say "============================================================", :green
  say " Boilerplate ready!", :green
  say "============================================================", :green
  say ""
  say "Next steps:", :yellow
  say "  1. Copy .env.example to .env and fill in your keys"
  say "  2. Generate LOCKBOX_MASTER_KEY: bin/rails db:encryption:init"
  say "  3. Set up acts_as_tenant if you need multi-tenancy"
  say "  4. Review config/initializers/sentry.rb"
  say "  5. Run: bin/dev"
  say ""
  say "Admin-only routes (require user.admin? == true):", :yellow
  say "  /sidekiq  — background jobs"
  say "  /pghero   — Postgres performance"
  say "  /flipper  — feature flags"
  say ""
end
