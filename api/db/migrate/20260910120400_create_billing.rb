# frozen_string_literal: true

class CreateBilling < ActiveRecord::Migration[8.1]
  def change
    create_table :plans do |t|
      t.references :community, null: false, foreign_key: true
      t.string  :name, null: false
      t.string  :slug, null: false
      t.text    :description
      t.string  :interval, null: false, default: "month"
      t.integer :amount_cents, null: false, default: 0
      t.string  :currency, null: false, default: "GBP"
      t.integer :trial_days, null: false, default: 0
      t.string  :provider_price_id
      t.jsonb   :features, null: false, default: []
      t.boolean :visible, null: false, default: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :plans, %i[community_id slug], unique: true
    add_check_constraint :plans, "interval IN ('month','year','one_time')", name: "plans_interval_check"
    add_check_constraint :plans, "amount_cents >= 0", name: "plans_amount_check"

    create_table :subscriptions do |t|
      t.references :community, null: false, foreign_key: true
      t.references :membership, null: false, foreign_key: true
      t.references :plan, null: false, foreign_key: true
      t.string   :provider, null: false, default: "stripe"
      t.string   :provider_ref
      t.string   :status, null: false, default: "trialing"
      t.datetime :trial_ends_at
      t.datetime :current_period_end
      t.boolean  :cancel_at_period_end, null: false, default: false
      t.datetime :cancelled_at
      t.timestamps
    end
    add_index :subscriptions, :provider_ref, unique: true, where: "provider_ref IS NOT NULL"
    add_index :subscriptions, %i[membership_id status]
    add_check_constraint :subscriptions,
                         "status IN ('trialing','active','past_due','cancelled','incomplete')",
                         name: "subscriptions_status_check"

    create_table :payments do |t|
      t.references :community, null: false, foreign_key: true
      t.references :subscription, foreign_key: true
      t.integer  :amount_cents, null: false
      t.string   :currency, null: false
      t.string   :status, null: false
      t.string   :provider_ref
      t.string   :invoice_url
      t.datetime :paid_at
      t.timestamps
    end
    add_index :payments, :provider_ref, unique: true, where: "provider_ref IS NOT NULL"

    create_table :coupons do |t|
      t.references :community, null: false, foreign_key: true
      t.string   :code, null: false
      t.integer  :percent_off
      t.integer  :amount_off_cents
      t.string   :duration, null: false, default: "once"
      t.integer  :max_redemptions
      t.integer  :redemptions_count, null: false, default: 0
      t.datetime :expires_at
      t.timestamps
    end
    add_index :coupons, %i[community_id code], unique: true

    # The idempotency spine. Stripe retries, delivers out of order, and occasionally
    # double-delivers; the unique index is what makes every handler safe to replay.
    create_table :webhook_events do |t|
      t.string   :provider, null: false
      t.string   :provider_event_id, null: false
      t.string   :event_type, null: false
      t.jsonb    :payload, null: false, default: {}
      t.datetime :processed_at
      t.text     :error_message
      t.integer  :attempts, null: false, default: 0
      t.timestamps
    end
    add_index :webhook_events, %i[provider provider_event_id], unique: true
    add_index :webhook_events, :processed_at, where: "processed_at IS NULL"
  end
end
