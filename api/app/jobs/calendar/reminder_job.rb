# frozen_string_literal: true

module Calendar
  # Two reminders per occurrence: a day before, so people can move things, and fifteen
  # minutes before, so they actually turn up. Each is stamped on the RSVP row, which is
  # what makes a retry safe — a job that runs twice does not send twice.
  class ReminderJob < ApplicationJob
    queue_as :notifications

    WINDOWS = {
      reminded_24h_at: { lead: 24.hours, slack: 1.hour },
      reminded_15m_at: { lead: 15.minutes, slack: 10.minutes }
    }.freeze

    def perform
      Community.find_each do |community|
        ActsAsTenant.with_tenant(community) { remind_for(community) }
      end
    end

    private

    def remind_for(_community)
      WINDOWS.each do |column, window|
        target = Time.current + window[:lead]

        EventOccurrence.upcoming
                       .where(starts_at: target..(target + window[:slack]))
                       .includes(:event)
                       .find_each { |occurrence| notify(occurrence, column) }
      end
    end

    def notify(occurrence, column)
      occurrence.event_rsvps.going.where(column => nil).includes(:user).find_each do |rsvp|
        Notification.deliver!(
          user: rsvp.user, kind: "event_reminder", subject: occurrence,
          data: { title: occurrence.event.title,
                  starts_at: occurrence.starts_at,
                  location_url: occurrence.event.location_url }
        )
        rsvp.update_columns(column => Time.current)
      end
    end
  end
end
