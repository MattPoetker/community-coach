# frozen_string_literal: true

module Notifications
  # Fans the digest out per community so one slow mailer cannot hold up the rest.
  class DailyDigestJob < ApplicationJob
    queue_as :notifications

    def perform
      Community.find_each { DigestJob.perform_later(_1.id) }
    end
  end
end
