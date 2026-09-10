# frozen_string_literal: true

class CreateClassroom < ActiveRecord::Migration[8.1]
  def change
    create_table :video_assets do |t|
      t.references :community, null: false, foreign_key: true
      t.string  :status, null: false, default: "uploading"
      t.string  :provider, null: false, default: "local"
      t.string  :provider_ref
      t.string  :original_filename
      t.integer :duration_seconds
      t.jsonb   :renditions, null: false, default: []
      t.string  :thumbnail_key
      t.text    :error_message
      t.timestamps
    end
    add_index :video_assets, %i[community_id status]
    add_check_constraint :video_assets, "status IN ('uploading','processing','ready','failed')",
                         name: "video_assets_status_check"

    create_table :courses do |t|
      t.references :community, null: false, foreign_key: true
      t.string  :title, null: false
      t.string  :slug, null: false
      t.text    :description
      t.string  :cover_key
      t.integer :position, null: false, default: 0
      # The single gate format, shared with categories and lessons. Evaluated by
      # Access::Resolver. `min_level` is inert until gamification ships in v2.
      t.jsonb   :access_rule, null: false, default: {}
      t.datetime :published_at
      t.timestamps
    end
    add_index :courses, %i[community_id slug], unique: true

    create_table :course_modules do |t|
      t.references :community, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.string  :title, null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :course_modules, %i[course_id position]

    create_table :lessons do |t|
      t.references :community, null: false, foreign_key: true
      t.references :course_module, null: false, foreign_key: true
      t.references :video_asset, foreign_key: true
      t.string  :title, null: false
      t.string  :slug, null: false
      t.jsonb   :body, null: false, default: {}
      t.integer :position, null: false, default: 0
      t.string  :drip_kind, null: false, default: "none"
      t.integer :drip_days
      t.datetime :drip_at
      t.jsonb   :access_rule, null: false, default: {}
      t.datetime :published_at
      t.timestamps
    end
    add_index :lessons, %i[course_module_id position]
    add_check_constraint :lessons, "drip_kind IN ('none','days_after_join','fixed_date')",
                         name: "lessons_drip_kind_check"

    create_table :lesson_progresses do |t|
      t.references :community, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :lesson, null: false, foreign_key: true
      t.string   :state, null: false, default: "started"
      t.integer  :seconds_watched, null: false, default: 0
      t.integer  :resume_at_seconds, null: false, default: 0
      t.datetime :completed_at
      t.timestamps
    end
    add_index :lesson_progresses, %i[user_id lesson_id], unique: true
    add_index :lesson_progresses, %i[community_id user_id state]
    add_check_constraint :lesson_progresses, "state IN ('started','completed')",
                         name: "lesson_progresses_state_check"
  end
end
