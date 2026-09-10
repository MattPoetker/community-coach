# frozen_string_literal: true

class CreateCalendar < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.references :community, null: false, foreign_key: true
      t.references :host, null: false, foreign_key: { to_table: :users }
      t.string  :title, null: false
      t.text    :description
      t.datetime :starts_at, null: false
      t.integer :duration_minutes, null: false, default: 60
      # UTC instant plus the IANA zone it was authored in. A weekly 09:00 call must stay
      # 09:00 local across a DST boundary; UTC alone silently shifts it twice a year.
      t.string  :timezone, null: false
      t.string  :rrule
      t.datetime :recurrence_end_at
      t.string  :location_kind, null: false, default: "url"
      t.string  :location_url
      t.jsonb   :access_rule, null: false, default: {}
      t.datetime :cancelled_at
      t.timestamps
    end
    add_index :events, %i[community_id starts_at]
    add_check_constraint :events,
                         "location_kind IN ('zoom','meet','jitsi','url','in_person')",
                         name: "events_location_kind_check"

    # Recurring events are materialised for a rolling horizon rather than expanded per
    # request. "What is on this month" then becomes one indexed range scan, and
    # per-occurrence overrides fall out for free.
    create_table :event_occurrences do |t|
      t.references :community, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.boolean  :overridden, null: false, default: false
      t.datetime :cancelled_at
      t.timestamps
    end
    add_index :event_occurrences, %i[community_id starts_at]
    add_index :event_occurrences, %i[event_id starts_at], unique: true

    create_table :event_rsvps do |t|
      t.references :community, null: false, foreign_key: true
      t.references :event_occurrence, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string   :state, null: false, default: "going"
      t.datetime :reminded_24h_at
      t.datetime :reminded_15m_at
      t.timestamps
    end
    add_index :event_rsvps, %i[event_occurrence_id user_id], unique: true
    add_check_constraint :event_rsvps, "state IN ('going','maybe','declined')",
                         name: "event_rsvps_state_check"

    create_table :recordings do |t|
      t.references :community, null: false, foreign_key: true
      t.references :event_occurrence, null: false, foreign_key: true
      t.references :video_asset, null: false, foreign_key: true
      t.datetime :published_at
      t.timestamps
    end
  end
end
