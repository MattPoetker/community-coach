# frozen_string_literal: true

module Api
  module V1
    class WebhooksController < ApplicationController
      skip_before_action :authenticate!
      skip_before_action :require_community!
      skip_before_action :verify_request_origin!
      skip_after_action :verify_authorized

      # Signature verification is the authentication for this endpoint. Without it anyone
      # who can reach the URL can grant themselves a subscription.
      def stripe
        event = verified_stripe_event
        record = WebhookEvent.record!(provider: "stripe", event_id: event["id"],
                                      type: event["type"], payload: event.to_hash.deep_stringify_keys)

        Billing::ProcessWebhookJob.perform_later(record.id)
        head :ok
      rescue JSON::ParserError, ::Stripe::SignatureVerificationError => e
        Rails.logger.warn("[webhook] rejected: #{e.class}")
        head :bad_request
      end

      private

      def verified_stripe_event
        ::Stripe::Webhook.construct_event(
          request.body.read,
          request.headers["Stripe-Signature"],
          ENV.fetch("STRIPE_WEBHOOK_SECRET")
        )
      end
    end
  end
end
