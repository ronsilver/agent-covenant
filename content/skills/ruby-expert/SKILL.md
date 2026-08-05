---
name: ruby-expert
description: "Ruby on Rails web development: ActiveRecord/PostgreSQL, BDD/TDD testing with RSpec and Capybara, service objects, background jobs with Sidekiq, and dependency management with Bundler. Use when building Rails applications, writing migrations, implementing service objects, testing Rails features, or extending Rails engines. Trigger: Ruby, Rails, RSpec, Capybara, ActiveRecord, Sidekiq. Do NOT trigger for: Go services, Python backends, frontend TypeScript."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: backend
  status: stable
---
# Ruby Expert

**Ruby ecosystem: Rails, ActiveRecord, testing with RSpec.**

## Core Stack

- Language: Ruby 3.x
- Framework: Ruby on Rails 7+ (MVC, ActiveRecord, ActionMailer, ActiveJob)
- Background Jobs: Sidekiq / ActiveJob
- Database: PostgreSQL (via ActiveRecord)
- Testing: RSpec + Capybara + FactoryBot
- Dependencies: Bundler + Gemfile
- Linting: RuboCop
- Background: Sidekiq / ActiveJob

## Project Structure

```
app/
  controllers/     # thin controllers
  models/          # ActiveRecord models + Rails decorators
  views/           # ERB/Slim templates
  services/        # business logic (service objects)
  decorators/      # model/controller decorators
db/
  migrate/         # Rails migrations
spec/
  models/
  controllers/
  features/        # Capybara integration tests
  factories/       # FactoryBot definitions
```



```ruby
# app/models/concerns/tenant_scoped.rb
module TenantScoped
  extend ActiveSupport::Concern

  included do
    belongs_to :tenant
    default_scope { where(tenant: Current.tenant) }
  end
end
```

## Workflow

1. Define data model (ActiveRecord migration + model validations)
2. Implement service objects for business logic (not in controller/model)
3. Thin controllers: extract params -> call service -> render
4. Write RSpec tests (unit + integration + Capybara features)
5. RuboCop lint before commit

## Testing

```ruby
# spec/models/article_spec.rb
RSpec.describe Article, type: :model do
  subject { build(:article, price: 19.99) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_numericality_of(:price).is_greater_than(0) }

  describe "#tenant" do
    let(:tenant) { create(:tenant) }

    it "returns associated tenant name" do
      subject.tenant = tenant
      expect(subject.tenant_name).to eq(tenant.name)
    end
  end
end

# spec/features/booking_spec.rb
RSpec.feature "Booking", type: :feature do
  scenario "creates booking" do
    article = create(:article, name: "Test Item")
    visit article_path(article)
    click_button "Add to Booking"
    click_button "Submit Booking"
    expect(page).to have_content("Item confirmed")
  end
end
```

- FactoryBot over fixtures. Capybara for feature specs.
- Test decorators and concerns in isolation.

## Constraints

- NEVER modify engine source code directly — use decorators
- NEVER skip validations in ActiveRecord (`save(validate: false)` only with explicit reason)
- NEVER business logic in controllers — service objects
- NEVER `eval` or `class_eval` on user input
- ALWAYS use strong parameters (`params.require(:model).permit(...)`)
- ALWAYS run `bundle exec rubocop` before commit
- NEVER log PII (customer names, emails, addresses) in plain text
- NEVER store sensitive data in plain text — use a dedicated secrets/PII vault service

## Overview

Ruby on Rails for web application development. This skill covers ActiveRecord models and migrations, service objects, RSpec testing with Capybara, engine customization via decorators, and background job processing with Sidekiq.

## Quick Reference

| Component | Technology | Purpose |
|---|---|---|
| Framework | Ruby on Rails 7+ MVC | Web application structure |
| Background Jobs | Sidekiq + ActiveJob | Async processing, scheduled tasks, webhooks |
| Customization | Decorators + Deface overrides | Extend Rails without modifying source |
| Testing | RSpec + Capybara + FactoryBot | BDD acceptance tests |
| Background | Sidekiq / ActiveJob | Async job processing |

## Workflow

1. Define data model via ActiveRecord migration + model validations
2. Implement service objects for business logic (never in controller/model)
3. Write thin controller: extract params → call service → render response
4. Customize Rails via decorators (`class_eval` on models) and Deface overrides (views)
5. Write RSpec tests: model specs, controller specs, Capybara feature specs
6. Run `bundle exec rubocop` before commit — stop on lint failures

## Anti-patterns

FAIL: Modifying Rails engine gem source code directly
PASS: Always use decorators and Deface overrides

```ruby
# FAIL:
# Editing rails_core gem directly — lost on bundle update
# app/models/rails/product.rb (within gem)

# PASS:
# app/decorators/rails/product_decorator.rb
Rails::Article.class_eval do
  belongs_to :tenant, class_name: "Tenant"
end
```

FAIL: Business logic in Rails controllers or models
PASS: Extract into service objects

```ruby
# FAIL:
class BookingsController < ApplicationController
  def create
    @booking = Rails::Booking.new(booking_params)
    @booking.calculate_fees   # business logic in controller
    @booking.apply_discounts   # business logic in controller
    @booking.save!
  end
end

# PASS:
class BookingService
  def call(booking_params)
    booking = Rails::Booking.new(booking_params)
    FeeCalculator.apply(booking)
    DiscountApplier.apply(booking)
    booking.save!
    booking
  end
end
```

FAIL: Using `save(validate: false)` without documented reason
PASS: Always validate and handle errors explicitly

```ruby
# FAIL:
booking.save(validate: false)  # why? undocumented

# PASS:
booking.save!  # raises on validation failure
# or with explicit skip documented:
booking.save(validate: false)  # Skipping validation because partial restore from archive table
```

## References

- [Ruby on Rails Guides](https://guides.rubyonrails.org/) (last_verified: 2025-02)
- [Rails Documentation](https://guides.rubyonrails.org/) (last_verified: 2024-11)
- [RSpec Rails Documentation](https://relishapp.com/rspec/rspec-rails/docs) (last_verified: 2024-10)

- [references/rails-conventions.md](references/rails-conventions.md)

## Verification Checklist

- [ ] Rails customizations use decorators/overrides (never modify engine source directly)
- [ ] Business logic extracted into service objects (not in controllers or models)
- [ ] Strong parameters used in all controllers (`params.require(...).permit(...)`)
- [ ] `bundle exec rubocop` run and all violations resolved
- [ ] No PII logged in plain text (names, emails, addresses)
- [ ] No sensitive data stored in plain text — routed via dedicated secrets/PII vault service
- [ ] `save(validate: false)` only used with explicit documented reason

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Rails decorator not loading | File not in `app/decorators/` or gem autoload order | Verify file path follows Rails decorator naming convention; restart server |
| Migration fails on production | ALTER TABLE locks or constraint violation | Wrap in transaction; use `safe_` methods for large tables; add `NOT VALID` for FK |
| Capybara test can't find element | Selector mismatch or JS not executed | Use more specific selectors; add `wait:` option; check for JS errors in browser console |
| Rails decorator loads but overridden method not called (edge case: monkey-patch load order) | Another decorator or gem overrides same method; last-loaded wins | Use `prepend` instead of `class_eval` for controlled override order; verify load order in `config/initializers` |

| [WARN] Rails gem autoload order: decorator defined before original class loads | Zeitwerk (Rails 6+) autoloads in alphabetical order; decorator can load before parent class | Use `Rails.configuration.to_prepare` block to defer decorator loading; check class exists before reopening |
