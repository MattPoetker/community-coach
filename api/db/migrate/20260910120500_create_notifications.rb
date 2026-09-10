# frozen_string_literal: true

class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :community, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :actor, foreign_key: { to_table: :users }
      t.references :subject, polymorphic: true
      t.string   :kind, null: false
      t.jsonb    :data, null: false, default: {}
      t.integer  :group_count, null: false, default: 1
      t.datetime :read_at
      t.datetime :emailed_at
      t.timestamps
    end
    add_index :notifications, %i[user_id read_at created_at], order: { created_at: :desc },
              name: "index_notifications_on_inbox"
    # Ten likes on one post become one row that increments, not ten rows.
    add_index :notifications, %i[user_id subject_type subject_id kind],
              name: "index_notifications_for_grouping"

    create_table :notification_preferences do |t|
      t.references :community, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string  :kind, null: false
      t.boolean :in_app, null: false, default: true
      t.string  :email, null: false, default: "instant"
      t.boolean :push, null: false, default: false
      t.timestamps
    end
    add_index :notification_preferences, %i[community_id user_id kind], unique: true,
              name: "index_notification_preferences_uniqueness"
    add_check_constraint :notification_preferences, "email IN ('off','instant','daily')",
                         name: "notification_preferences_email_check"

    create_table :push_subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :endpoint, null: false
      t.string :p256dh_key, null: false
      t.string :auth_key, null: false
      t.timestamps
    end
    add_index :push_subscriptions, :endpoint, unique: true

    create_table :audit_logs do |t|
      t.references :community, foreign_key: true
      t.references :actor, foreign_key: { to_table: :users }
      t.references :subject, polymorphic: true
      t.string  :action, null: false
      t.jsonb   :changes_made, null: false, default: {}
      t.string  :ip_address
      t.timestamps
    end
    add_index :audit_logs, %i[community_id created_at], order: { created_at: :desc }
  end
end
