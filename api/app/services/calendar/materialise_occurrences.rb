# frozen_string_literal: true

module Calendar
  # Expands an event's RRULE into concrete rows for a rolling horizon.
  #
  # Storing occurrences rather than expanding rules per request turns "what is on this
  # month" into a single indexed range scan, and gives per-occurrence overrides (one
  # session moved, one cancelled) somewhere to live.
  class MaterialiseOccurrences
    def initialize(event, horizon: Event::MATERIALISE_HORIZON)
      @event = event
      @horizon = horizon
    end

    def self.call(...) = new(...).call

    def call
      starts = occurrence_starts
      ActiveRecord::Base.transaction do
        upsert(starts)
        prune(starts)
      end
      starts.size
    end

    private

    def zone = ActiveSupport::TimeZone[@event.timezone] || Time.zone

    def occurrence_starts
      return [@event.starts_at] unless @event.recurring?

      schedule.occurrences(horizon_end).map { |o| o.to_time.in_time_zone(zone) }
    rescue StandardError => e
      Rails.logger.warn("[calendar] RRULE expansion failed for event #{@event.id}: #{e.message}")
      [@event.starts_at]
    end

    def schedule
      IceCube::Schedule.new(@event.starts_at.in_time_zone(zone)).tap do |s|
        s.add_recurrence_rule(IceCube::Rule.from_ical(@event.rrule))
      end
    end

    def horizon_end
      [@horizon.from_now, @event.recurrence_end_at].compact.min
    end

    # Rows an admin has edited individually are left alone — regenerating them would
    # silently discard the override, which is the whole reason occurrences are rows.
    def upsert(starts)
      starts.each do |start|
        occurrence = @event.event_occurrences.find_or_initialize_by(starts_at: start)
        next if occurrence.persisted? && occurrence.overridden?

        occurrence.community = @event.community
        occurrence.ends_at = start + @event.duration_minutes.minutes
        occurrence.save!
      end
    end

    def prune(starts)
      @event.event_occurrences
            .where.not(starts_at: starts)
            .where(overridden: false)
            .where(starts_at: Time.current..)
            .destroy_all
    end
  end
end
