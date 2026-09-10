# frozen_string_literal: true

class CreateCommunityFeed < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.references :community, null: false, foreign_key: true
      t.string  :name, null: false
      t.string  :slug, null: false
      t.text    :description
      t.integer :position, null: false, default: 0
      t.string  :post_permission, null: false, default: "all"
      t.jsonb   :access_rule, null: false, default: {}
      t.timestamps
    end
    add_index :categories, %i[community_id slug], unique: true
    add_index :categories, %i[community_id position]

    create_table :posts do |t|
      t.references :community, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string  :title, null: false
      # Rich text is stored as a constrained ProseMirror document, not HTML. Sanitising at
      # render is where XSS lives; storing a document and rendering from it removes the class.
      t.jsonb   :body, null: false, default: {}
      t.text    :body_text, null: false, default: ""
      t.string  :kind, null: false, default: "discussion"
      t.datetime :pinned_at
      t.datetime :locked_at
      t.datetime :edited_at
      t.datetime :deleted_at
      t.integer :comments_count, null: false, default: 0
      t.integer :reactions_count, null: false, default: 0
      t.datetime :last_activity_at, null: false
      t.timestamps
    end
    # The feed's covering index: newest activity first, deleted rows excluded.
    add_index :posts, %i[community_id category_id last_activity_at],
              order: { last_activity_at: :desc }, where: "deleted_at IS NULL",
              name: "index_posts_on_feed"
    add_index :posts, %i[community_id pinned_at], where: "pinned_at IS NOT NULL"
    add_check_constraint :posts, "kind IN ('discussion','poll','announcement')", name: "posts_kind_check"

    create_table :comments do |t|
      t.references :community, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :parent, foreign_key: { to_table: :comments }
      t.jsonb   :body, null: false, default: {}
      t.text    :body_text, null: false, default: ""
      # ltree gives ordered subtree fetches in one indexed query; the adjacency-list plus
      # recursive CTE alternative does not do that cheaply at depth.
      t.column  :path, :ltree, null: false
      t.integer :depth, null: false, default: 0
      t.integer :reactions_count, null: false, default: 0
      t.datetime :edited_at
      t.datetime :deleted_at
      t.timestamps
    end
    add_index :comments, %i[post_id path]
    add_index :comments, :path, using: :gist
    add_check_constraint :comments, "depth >= 0 AND depth <= 5", name: "comments_depth_check"

    create_table :reactions do |t|
      t.references :community, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :reactable, polymorphic: true, null: false
      t.string :kind, null: false, default: "like"
      t.timestamps
    end
    add_index :reactions, %i[reactable_type reactable_id user_id kind], unique: true,
              name: "index_reactions_uniqueness"

    create_table :polls do |t|
      t.references :post, null: false, foreign_key: true, index: { unique: true }
      t.boolean  :multiple, null: false, default: false
      t.datetime :closes_at
      t.timestamps
    end

    create_table :poll_options do |t|
      t.references :poll, null: false, foreign_key: true
      t.string  :label, null: false
      t.integer :position, null: false, default: 0
      t.integer :votes_count, null: false, default: 0
      t.timestamps
    end

    create_table :poll_votes do |t|
      t.references :poll_option, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
    add_index :poll_votes, %i[poll_option_id user_id], unique: true

    create_table :mentions do |t|
      t.references :community, null: false, foreign_key: true
      t.references :source, polymorphic: true, null: false
      t.references :mentioned_user, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :mentions, %i[source_type source_id mentioned_user_id], unique: true,
              name: "index_mentions_uniqueness"

    # Why a user hears about a thread. Drives notification fan-out and the unsubscribe link.
    create_table :thread_subscriptions do |t|
      t.references :community, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :subject, polymorphic: true, null: false
      t.string  :reason, null: false, default: "manual"
      t.boolean :muted, null: false, default: false
      t.timestamps
    end
    add_index :thread_subscriptions, %i[subject_type subject_id user_id], unique: true,
              name: "index_thread_subscriptions_uniqueness"

    create_table :reports do |t|
      t.references :community, null: false, foreign_key: true
      t.references :reporter, null: false, foreign_key: { to_table: :users }
      t.references :resolved_by, foreign_key: { to_table: :users }
      t.references :subject, polymorphic: true, null: false
      t.string   :reason, null: false
      t.text     :detail
      t.string   :state, null: false, default: "open"
      t.datetime :resolved_at
      t.timestamps
    end
    add_index :reports, %i[community_id state]
  end
end
