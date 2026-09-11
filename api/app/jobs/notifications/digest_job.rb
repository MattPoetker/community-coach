# frozen_string_literal: true

module Notifications
  # One email per person per community per day, covering everything they chose to receive
  # daily and have not already read.
  class DigestJob < ApplicationJob
    queue_as :notifications

    def perform(community_id)
      with_community(community_id) do |community|
        recipients = NotificationPreference.where(community: community, email: "daily")
                                           .group(:user_id)
                                           .pluck(:user_id, Arel.sql("array_agg(kind)"))

        recipients.each { |user_id, kinds| deliver(community, user_id, kinds) }
      end
    end

    private

    def deliver(community, user_id, kinds)
      pending = Notification.where(user_id: user_id, community: community, kind: kinds)
                            .where(read_at: nil, emailed_at: nil)
                            .where(created_at: 25.hours.ago..)
                            .order(created_at: :desc)
                            .limit(50)
                            .to_a
      return if pending.empty?

      NotificationMailer.digest(User.find(user_id), community, pending).deliver_now
      Notification.where(id: pending.map(&:id)).update_all(emailed_at: Time.current)
    end
  end
end
