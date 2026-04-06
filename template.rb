# Rails Boilerplate Template
# Usage: rails new myapp --database=postgresql --template=template.rb

def source_paths
  [__dir__] + Array(super)
end

# ============================================================
# Gems
# ============================================================

# Auth
gem "devise"
gem "devise-passwordless"
gem "omniauth-google-oauth2"
gem "omniauth-apple"
gem "omniauth-rails_csrf_protection"

# Styling
gem "tailwindcss-rails"

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
end

gem_group :development do
  gem "letter_opener"
end

gem_group :test do
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

      # Google OAuth
      GOOGLE_CLIENT_ID=
      GOOGLE_CLIENT_SECRET=

      # Apple OAuth
      APPLE_CLIENT_ID=
      APPLE_CLIENT_SECRET=

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

      GOOGLE_CLIENT_ID=
      GOOGLE_CLIENT_SECRET=

      APPLE_CLIENT_ID=
      APPLE_CLIENT_SECRET=

      LOCKBOX_MASTER_KEY=
    ENV
  end

  append_to_file ".gitignore", "\n.env\nnode_modules/\n"

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
  # Tailwind CSS + DaisyUI
  # --------------------------------------------------------
  generate "tailwindcss:install"

  run "npm install daisyui"

  append_to_file "app/assets/tailwind/application.css", '@plugin "daisyui";'

  # --------------------------------------------------------
  # Authentication (Devise)
  # --------------------------------------------------------
  generate "devise:install"
  generate "devise", "User"

  # Add omniauth + magic links to the devise call
  gsub_file "app/models/user.rb",
    /devise :database_authenticatable.*:validatable/m,
    "devise :database_authenticatable, :registerable,\n" \
    "         :recoverable, :rememberable, :validatable,\n" \
    "         :omniauthable, omniauth_providers: %i[google_oauth2 apple],\n" \
    "         :magic_link_authenticatable"

  # Add provider/uid columns for OAuth
  generate "migration", "AddOmniauthToUsers provider:string uid:string"

  # Add from_omniauth to User model
  inject_into_file "app/models/user.rb", before: "end\n" do
    <<~RUBY

      def self.from_omniauth(auth)
        where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
          user.email = auth.info.email
          user.password = Devise.friendly_token[0, 20]
        end
      end
    RUBY
  end

  # Configure mailer URL options for Devise
  environment 'config.action_mailer.default_url_options = { host: "localhost", port: 3000 }', env: "development"

  # Configure OmniAuth providers in Devise initializer
  inject_into_file "config/initializers/devise.rb",
    after: "# config.omniauth :github, 'APP_ID', 'APP_SECRET', scope: 'user,public_repo'\n" do
    <<~RUBY
      config.omniauth :google_oauth2, ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"]
      config.omniauth :apple, ENV["APPLE_CLIENT_ID"], ENV["APPLE_CLIENT_SECRET"]
    RUBY
  end

  # OmniAuth callbacks controller
  FileUtils.mkdir_p "app/controllers/users"
  create_file "app/controllers/users/omniauth_callbacks_controller.rb" do
    <<~RUBY
      class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
        def google_oauth2
          handle_auth "Google"
        end

        def apple
          handle_auth "Apple"
        end

        private

        def handle_auth(kind)
          @user = User.from_omniauth(request.env["omniauth.auth"])
          if @user.persisted?
            sign_in_and_redirect @user, event: :authentication
            set_flash_message(:notice, :success, kind: kind) if is_navigational_format?
          else
            session["devise.auth_data"] = request.env["omniauth.auth"].except(:extra)
            redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\\n")
          end
        end
      end
    RUBY
  end

  # devise-passwordless: generates mailer and token migration
  run "bundle exec rails generate devise_passwordless:install"

  # Devise routes (omniauth callbacks + magic links)
  route <<~RUBY
    devise_for :users, controllers: {
      omniauth_callbacks: "users/omniauth_callbacks",
      magic_links: "users/magic_links"
    }
  RUBY

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

  # --------------------------------------------------------
  # Flipper (feature flags)
  # --------------------------------------------------------
  generate "flipper:active_record"

  route <<~RUBY
    require "sidekiq/web"

    authenticate :user, ->(u) { u.admin? } do
      mount Sidekiq::Web => "/sidekiq"
      mount PgHero::Engine => "/pghero"
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
  remove_file ".github/workflows/ci.yml"

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
  # Dockerfile — patch for Railway compatibility
  # --------------------------------------------------------

  # Add libffi-dev (required by fiddle gem in Ruby 3.4+),
  # nodejs and npm (required to install DaisyUI for Tailwind)
  gsub_file "Dockerfile",
    "build-essential git libpq-dev libvips libyaml-dev pkg-config",
    "build-essential git libffi-dev libpq-dev libvips libyaml-dev nodejs npm pkg-config"

  # Install JS dependencies before bundle install for better layer caching
  gsub_file "Dockerfile", "# Install application gems\nCOPY vendor/* ./vendor/\nCOPY Gemfile Gemfile.lock ./" do
    <<~DOCKERFILE.chomp
      # Install JS dependencies (DaisyUI for Tailwind)
      COPY package.json package-lock.json ./
      RUN npm ci

      # Install application gems
      COPY vendor/* ./vendor/
      COPY Gemfile Gemfile.lock ./
    DOCKERFILE
  end

  # --------------------------------------------------------
  # nixpacks.toml — Railway deployment
  # --------------------------------------------------------
  create_file "nixpacks.toml" do
    <<~TOML
      [phases.install]
      cmds = ["bundle install", "npm install"]

      [start]
      cmd = "./bin/rails server"
    TOML
  end

  # --------------------------------------------------------
  # Production config — single database for Railway
  # --------------------------------------------------------

  # Use DATABASE_URL for all production connections (single Railway Postgres)
  gsub_file "config/database.yml", /^production:.*\z/m do
    <<~YAML
      production:
        <<: *default
        url: <%= ENV["DATABASE_URL"] %>
    YAML
  end

  # Enable SSL, remove solid_queue multi-database connects_to
  gsub_file "config/environments/production.rb",
    "# config.assume_ssl = true",
    "config.assume_ssl = true"

  gsub_file "config/environments/production.rb",
    "# config.force_ssl = true",
    "config.force_ssl = true"

  gsub_file "config/environments/production.rb",
    /config\.solid_queue\.connects_to = .+\n/, ""

  # Remove connects_to from Solid Cable (points to secondary :cable database)
  gsub_file "config/cable.yml", /  connects_to:\n    database:\n      writing: cable\n/, ""

  # Remove database: cache from Solid Cache config
  gsub_file "config/cache.yml", /  database: cache\n/, ""

  # Merge Solid Cache/Queue/Cable table definitions into main schema.rb
  # (needed because db:prepare only loads db/schema.rb with a single-database setup)
  after_schema_merge = []
  after_fk_merge = []

  %w[db/cache_schema.rb db/queue_schema.rb db/cable_schema.rb].each do |f|
    next unless File.exist?(f)
    content = File.read(f)
    content.scan(/  create_table .+?^  end$/m) { |t| after_schema_merge << t }
    content.scan(/  add_foreign_key .+$/) { |fk| after_fk_merge << fk }
  end

  unless after_schema_merge.empty?
    gsub_file "db/schema.rb", /^end\z/ do
      after_schema_merge.join("\n\n") + "\n\n" +
        after_fk_merge.join("\n") + "\n\n" +
        "end"
    end
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
  say "  3. Set up Pay (billing):", :yellow
  say "       bin/rails generate pay:install"
  say "       bin/rails db:migrate"
  say "       # Add `pay_customer` to your User model"
  say "  4. Set up acts_as_tenant if you need multi-tenancy"
  say "  5. Review config/initializers/sentry.rb"
  say "  6. Run: bin/dev"
  say ""
  say "Admin-only routes (require user.admin? == true):", :yellow
  say "  /sidekiq  — background jobs"
  say "  /pghero   — Postgres performance"
  say "  /flipper  — feature flags"
  say ""
  say "Deploying to Railway:", :yellow
  say "  1. Push to GitHub"
  say "  2. Create a new Railway project from your repo"
  say "  3. Add a Postgres plugin — DATABASE_URL is set automatically"
  say "  4. Set these environment variables in Railway:"
  say "       RAILS_MASTER_KEY  → contents of config/master.key"
  say "       LOCKBOX_MASTER_KEY → from bin/rails db:encryption:init"
  say ""
end
