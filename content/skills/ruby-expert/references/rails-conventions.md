# Rails Conventions for this project

## Project Structure
```
app/
  controllers/  # thin — parse params, call service, render
  models/       # ActiveRecord + validations + associations
  services/     # business logic (service objects)
  decorators/   # model/controller decorators for Rails engines
```

## Strong Parameters
```ruby
params.require(:order).permit(:quantity, :status, :tenant_id)
```
ALWAYS permit explicitly. NEVER permit all keys.

## Migrations
```ruby
class AddExternalIdToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :external_id, :string
    add_index :products, :external_id, unique: true
  end
end
```

## Background Jobs
```ruby
class ProcessOrderJob < ApplicationJob
  queue_as :orders
  def perform(order_id)
    # async processing
  end
end
```
Use Sidekiq or ActiveJob for long-running tasks.

## Security
- NEVER eval/class_eval on user input
- NEVER store sensitive data (tokenize via dedicated service)
- NEVER log PII (names, emails, addresses) in plain text
- ALWAYS use Bundler (not system gems)
