# Rails Boilerplate

An opinionated Rails application template for production-ready SaaS apps. Run one command and get auth, billing, background jobs, feature flags, analytics, encryption, audit logging, and CI — all wired up and ready to go.

## Requirements

- Ruby 3.3+
- Rails 8.0+
- PostgreSQL 14+
- Redis 7+

## Usage

```bash
rails new myapp --database=postgresql --template=https://raw.githubusercontent.com/jeffyip/rails-boilerplate/main/template.rb
```

Or clone and reference locally:

```bash
git clone https://github.com/jeffyip/rails-boilerplate.git
rails new myapp --database=postgresql --template=rails-boilerplate/template.rb
```

## What's included

### Authentication
[authentication-zero](https://github.com/lazaronixon/authentication-zero) — generates clean, readable auth code directly into your app. No Devise magic. You own every line.

### Background Jobs
[Sidekiq](https://github.com/sidekiq/sidekiq) with a sensible default queue configuration. The web UI is mounted at `/sidekiq` behind admin authentication.

### Payments
[Pay](https://github.com/pay-rails/pay) with Stripe. Supports subscriptions, one-time charges, and webhooks out of the box.

### Multi-tenancy
[acts_as_tenant](https://github.com/ErwinM/acts_as_tenant) is installed but intentionally not auto-configured — the tenant model is too app-specific to assume. See [setup notes](#multi-tenancy-setup) below.

### Feature Flags
[Flipper](https://github.com/flippercloud/flipper) with ActiveRecord adapter. The UI is mounted at `/flipper` behind admin authentication.

### Audit Logging
[PaperTrail](https://github.com/paper-trail-gem/paper_trail) — add `has_paper_trail` to any model you want to track.

### Error Tracking
[Sentry](https://sentry.io) — configured with Rails, Sidekiq, and breadcrumb logging. Only enabled in `production` and `staging` environments.

### Analytics
[Ahoy](https://github.com/ankane/ahoy) — first-party visit and event tracking. Own your analytics data.

### Encryption
[Lockbox](https://github.com/ankane/lockbox) for field-level encryption, paired with [blind_index](https://github.com/ankane/blind_index) for querying encrypted fields.

### File Storage
Active Storage configured for S3-compatible storage in production, disk storage in development.

### Admin Tools
| Path | Tool | Purpose |
|---|---|---|
| `/sidekiq` | Sidekiq Web | Monitor background jobs |
| `/pghero` | PgHero | Postgres performance, slow queries, index recommendations |
| `/flipper` | Flipper UI | Manage feature flags |

All admin routes require `current_user.admin?` to be true.

### User Impersonation
[Pretender](https://github.com/ankane/pretender) is wired into `ApplicationController`. Impersonate any user for support and debugging.

### Safe Migrations
[strong_migrations](https://github.com/ankane/strong_migrations) catches dangerous database migrations (missing indexes, non-null columns without defaults, etc.) before they cause production incidents.

### Testing
- [RSpec](https://rspec.info) with `--format documentation`
- [FactoryBot](https://github.com/thoughtbot/factory_bot_rails) with shorthand syntax included
- [Faker](https://github.com/faker-ruby/faker) for test data
- [Capybara](https://github.com/teamcapybara/capybara) + [Selenium](https://github.com/SeleniumHQ/selenium) for system tests
- [shoulda-matchers](https://github.com/thoughtbot/shoulda-matchers) for one-line model specs
- DatabaseCleaner pre-configured

### Linting & Security
- [StandardRB](https://github.com/standardrb/standard) — zero-config Ruby linting (RuboCop under the hood with fixed rules)
- [Brakeman](https://brakemanscanner.org) — static analysis security scanner for Rails

### CI
GitHub Actions workflow out of the box. Runs on every push and pull request to `main`:
1. Boots Postgres 16 and Redis 7 as services
2. Runs `db:create db:schema:load`
3. Runs RSpec
4. Runs StandardRB
5. Runs Brakeman

### Email
Letter Opener in development — emails open in the browser instead of being delivered.

### Environment
`dotenv-rails` with a pre-scaffolded `.env.example`. `.env` is gitignored.

---

## Post-install checklist

After running the template:

```bash
# 1. Fill in your environment variables
cp .env.example .env

# 2. Generate an encryption key for Lockbox
bin/rails db:encryption:init
# Copy the LOCKBOX_MASTER_KEY value into your .env

# 3. Add an admin user in the Rails console
bin/rails console
User.find_by(email: "you@example.com").update!(admin: true)

# 4. Start the app
bin/dev
```

## Multi-tenancy setup

`acts_as_tenant` is installed but not configured. When you're ready:

**1. Add the tenant model** (e.g. `Account`):
```bash
bin/rails generate model Account name:string subdomain:string
bin/rails db:migrate
```

**2. Scope your models:**
```ruby
class Project < ApplicationRecord
  acts_as_tenant :account
end
```

**3. Set the current tenant in `ApplicationController`:**
```ruby
class ApplicationController < ActionController::Base
  set_current_tenant_by_subdomain(:account, :subdomain)
  # or: set_current_tenant_through_filter
end
```

## Brakeman

Run a security scan at any time:

```bash
bundle exec brakeman
```

Triage false positives interactively (adds them to `config/brakeman.ignore`):

```bash
bundle exec brakeman -I
```

## Environment variables

| Variable | Description |
|---|---|
| `DATABASE_URL` | PostgreSQL connection string |
| `LOCKBOX_MASTER_KEY` | 64-char hex key for field encryption |
| `SENTRY_DSN` | Sentry project DSN |
| `STRIPE_PUBLIC_KEY` | Stripe publishable key |
| `STRIPE_PRIVATE_KEY` | Stripe secret key |
| `STRIPE_SIGNING_SECRET` | Stripe webhook signing secret |
| `AWS_ACCESS_KEY_ID` | S3-compatible storage access key |
| `AWS_SECRET_ACCESS_KEY` | S3-compatible storage secret |
| `AWS_BUCKET` | S3 bucket name |
| `AWS_REGION` | S3 region (default: `us-east-1`) |

## Philosophy

- **Generate code, don't hide it.** Auth, encryption config, and initializers are written into your app — not abstracted behind gem internals you can't read.
- **Own your data.** First-party analytics (Ahoy), first-party error tracking (Sentry), no third-party JS required.
- **Fail loudly in CI.** Tests, linting, and security scanning all run on every PR.
- **No lock-in.** No deployment target is baked in. Deploy to Fly, Render, Heroku, or your own infrastructure.

## Contributing

Pull requests welcome. Please open an issue first for significant changes.

## License

MIT
