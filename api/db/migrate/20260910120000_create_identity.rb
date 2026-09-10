# frozen_string_literal: true

class CreateIdentity < ActiveRecord::Migration[8.1]
  def change
    enable_extension "citext"   # case-insensitive email without a functional index
    enable_extension "ltree"    # comment threading
    enable_extension "pgcrypto"

    # Users are global. One identity can hold memberships in many communities, which is
    # what makes a single install able to host more than one community.
    create_table :users do |t|
      t.citext  :email_address, null: false
      t.string  :password_digest, null: false
      t.string  :name, null: false
      t.string  :timezone, null: false, default: "Etc/UTC"
      t.string  :locale, null: false, default: "en"
      t.datetime :confirmed_at
      t.string  :confirmation_token
      t.string  :password_reset_token
      t.datetime :password_reset_sent_at
      t.string  :totp_secret
      t.string  :totp_recovery_codes, array: true, default: []
      t.datetime :totp_enabled_at
      t.timestamps
    end
    add_index :users, :email_address, unique: true
    add_index :users, :confirmation_token, unique: true, where: "confirmation_token IS NOT NULL"
    add_index :users, :password_reset_token, unique: true, where: "password_reset_token IS NOT NULL"

    # Explicit session rows rather than opaque cookie state: needed for "log out everywhere",
    # a session list in security settings, and instant revocation when a member is banned.
    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string   :token_digest, null: false
      t.string   :user_agent
      t.string   :ip_address
      t.datetime :last_active_at, null: false
      t.datetime :expires_at, null: false
      t.timestamps
    end
    add_index :sessions, :token_digest, unique: true
    add_index :sessions, :expires_at

    create_table :communities do |t|
      t.string :slug, null: false
      t.string :name, null: false
      t.text   :description
      t.string :tagline
      t.string :privacy, null: false, default: "public"
      t.string :currency, null: false, default: "GBP"
      t.string :billing_mode, null: false, default: "direct"
      t.string :timezone, null: false, default: "Etc/UTC"
      t.jsonb  :branding, null: false, default: {}
      t.jsonb  :settings, null: false, default: {}
      t.datetime :published_at
      t.timestamps
    end
    add_index :communities, :slug, unique: true
    add_check_constraint :communities, "privacy IN ('public','private','secret')", name: "communities_privacy_check"
    add_check_constraint :communities, "billing_mode IN ('direct','connect')", name: "communities_billing_mode_check"

    create_table :custom_domains do |t|
      t.references :community, null: false, foreign_key: true
      t.string   :hostname, null: false
      t.datetime :verified_at
      t.string   :verification_token, null: false
      t.timestamps
    end
    add_index :custom_domains, :hostname, unique: true

    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :community, null: false, foreign_key: true
      t.string   :role, null: false, default: "member"
      t.string   :status, null: false, default: "active"
      t.datetime :joined_at
      t.datetime :last_seen_at
      t.datetime :suspended_at
      t.text     :suspension_reason
      # Reserved for gamification in v2. The schema carries it so the feature does not
      # require a backfill of every membership row later.
      t.integer  :points, null: false, default: 0
      t.integer  :level, null: false, default: 1
      t.timestamps
    end
    add_index :memberships, %i[user_id community_id], unique: true
    add_index :memberships, %i[community_id status]
    add_index :memberships, %i[community_id role]
    add_check_constraint :memberships, "role IN ('owner','admin','moderator','member')", name: "memberships_role_check"
    add_check_constraint :memberships, "status IN ('pending','active','past_due','suspended','cancelled')", name: "memberships_status_check"

    create_table :invitations do |t|
      t.references :community, null: false, foreign_key: true
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.citext   :email_address, null: false
      t.string   :role, null: false, default: "member"
      t.string   :token_digest, null: false
      t.datetime :accepted_at
      t.datetime :expires_at, null: false
      t.timestamps
    end
    add_index :invitations, :token_digest, unique: true
    add_index :invitations, %i[community_id email_address]

    create_table :join_requests do |t|
      t.references :community, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.jsonb    :answers, null: false, default: {}
      t.string   :state, null: false, default: "pending"
      t.datetime :reviewed_at
      t.timestamps
    end
    add_index :join_requests, %i[community_id user_id], unique: true
    add_index :join_requests, %i[community_id state]
  end
end
