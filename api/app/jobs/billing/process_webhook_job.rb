# frozen_string_literal: true

module Billing
  # Webhooks are acknowledged immediately and processed here, so a slow handler cannot
  # cause the provider to retry a delivery we already have.
  class ProcessWebhookJob < ApplicationJob
    queue_as :billing
    retry_on StandardError, wait: :polynomially_longer, attempts: 6

    def perform(webhook_event_id)
      record = WebhookEvent.find(webhook_event_id)
      Billing::Stripe::WebhookHandler.call(record)
    end
  end
end
