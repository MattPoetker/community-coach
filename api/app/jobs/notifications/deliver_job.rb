# frozen_string_literal: true

module Notifications
  # Decides how a notification actually reaches someone, according to their per-kind
  # preference. Runs out of band so a reply never waits on an SMTP connection.
  class DeliverJob < ApplicationJob
    queue_as :notifications

    def perform(notification_id)
      notification = Notification.unscoped.find_by(id: notification_id)
      return if notification.nil? || notification.emailed_at.present?

      with_community(notification.community_id) do
        preference = NotificationPreference.for(user: notification.user, kind: notification.kind)

        case preference.email
        when "instant" then deliver_instant(notification)
        when "daily" then nil # picked up by DigestJob
        end
      end
    end

    private

    def deliver_instant(notification)
      # A notification already read in the app needs no email. This is why delivery is a
      # job rather than inline: the gap is long enough for people to beat the mailer.
      return if notification.reload.read_at.present?

      NotificationMailer.instant(notification).deliver_now
      notification.update_columns(emailed_at: Time.current)
    end
  end
end
