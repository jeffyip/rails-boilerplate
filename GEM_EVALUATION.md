# Gem Evaluation

Star counts fetched via GitHub API on 2026-04-06.

## Auth

| Gem | Stars | Best Alternative | Alt Stars |
|-----|------:|-----------------|----------:|
| `devise` | 24,333 | `clearance` | 3,734 |
| `devise-passwordless` | 241 | `passwordless` (mikker) | 1,334 |
| `omniauth-google-oauth2` | 1,515 | `omniauth-github` | 463 |
| `omniauth-apple` | 275 | — | — |
| `omniauth-rails_csrf_protection` | 259 | — | — |

## Styling

| Gem | Stars | Best Alternative | Alt Stars |
|-----|------:|-----------------|----------:|
| `tailwindcss-rails` | 1,584 | `cssbundling-rails` | 630 |

## Background Jobs

| Gem | Stars | Best Alternative | Alt Stars |
|-----|------:|-----------------|----------:|
| `sidekiq` | 13,504 | `good_job` | 2,952 |

> `solid_queue` (2,406 stars) is the emerging zero-dependency alternative now bundled with Rails 8.

## File Storage

| Gem | Stars | Best Alternative | Alt Stars |
|-----|------:|-----------------|----------:|
| `aws-sdk-s3` | 3,642 | `google-cloud-storage` | 1,408 |

## Payments

| Gem | Stars | Best Alternative | Alt Stars |
|-----|------:|-----------------|----------:|
| `pay` | 2,218 | — | — |
| `stripe-ruby` | 2,110 | — | — |

## Multi-tenancy

| Gem | Stars | Best Alternative | Alt Stars |
|-----|------:|-----------------|----------:|
| `acts_as_tenant` | 1,687 | `apartment` | 2,684 |

> `apartment` has more stars but is largely unmaintained. `acts_as_tenant` is the safer active choice.

## Feature Flags

| Gem | Stars | Best Alternative | Alt Stars |
|-----|------:|-----------------|----------:|
| `flipper` | 3,926 | — | — |

## Audit Logging

| Gem | Stars | Best Alternative | Alt Stars |
|-----|------:|-----------------|----------:|
| `paper_trail` | 6,994 | `logidze` (Postgres-native) | 1,681 |

## Error Tracking

| Gem | Stars | Best Alternative | Alt Stars |
|-----|------:|-----------------|----------:|
| `sentry-ruby` | 985 | `rollbar-gem` | 478 |

> Sentry is the dominant choice here; both are low-star repos since the product is cloud-hosted.

## Ankane Suite

| Gem | Stars | Best Alternative | Alt Stars |
|-----|------:|-----------------|----------:|
| `strong_migrations` | 4,376 | — | — |
| `pretender` | 1,422 | — | — |
| `ahoy_matey` | 4,441 | — | — |
| `pghero` | 8,830 | — | — |
| `groupdate` | 3,883 | — | — |
| `lockbox` | 1,587 | `attr_encrypted` | 2,017 |
| `blind_index` | 707 | — | — |

> All Andrew Kane (ankane) gems — widely used, well-maintained, and generally best-in-class with no strong alternatives. `blind_index` (707) is the lowest but is complementary to `lockbox` and has no real substitute.

## Dev / Test

| Gem | Stars | Best Alternative | Alt Stars |
|-----|------:|-----------------|----------:|
| `dotenv-rails` | 6,736 | — | — |
| `rspec-rails` | 5,254 | `minitest` | 3,400 |
| `factory_bot_rails` | 3,123 | — | — |
| `faker` | 11,613 | — | — |
| `standard` (StandardRB) | 2,890 | `rubocop` | ~13,000 |
| `letter_opener` | 3,836 | `mailcatcher` | 6,748 |
| `shoulda-matchers` | 3,572 | — | — |

> `mailcatcher` (6,748) is more popular than `letter_opener` (3,836) — it runs a local SMTP server with a web UI vs. letter_opener's browser-tab approach.

## Summary: Gems to Watch

| Concern | Gem | Stars | Notes |
|---------|-----|------:|-------|
| Low adoption | `devise-passwordless` | 241 | Thin wrapper; consider `passwordless` gem if going standalone |
| Low adoption | `omniauth-apple` | 275 | Apple SSO is niche but necessary if supporting it |
| Low adoption | `blind_index` | 707 | No real alternative; pairs with `lockbox` |
| Consider swap | `letter_opener` | 3,836 | `mailcatcher` (6,748) has better UI for teams |
