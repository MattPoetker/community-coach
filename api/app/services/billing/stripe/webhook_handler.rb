# frozen_string_literal: true

module Billing
  module Stripe
    # Entitlement is derived from local `subscriptions` rows only — never from a live API
    # call in the request path. That keeps the paywall working when Stripe is slow or down,
    # and makes access decisions testable without a network.
    class WebhookHandler
      HANDLED = %w[
        checkout.session.completed
        customer.subscription.created
        customer.subscription.updated
        customer.subscription.deleted
        invoice.paid
        invoice.payment_failed
      ].freeze

      def initialize(event_record)
        @record = event_record
        @event = event_record.payload
      end

      def self.call(...) = new(...).call

      def call
        return :ignored unless HANDLED.include?(@record.event_type)

        @record.process! do
          ActsAsTenant.without_tenant { dispatch }
        end
      end

      private

      def object = @event.dig("data", "object") || {}

      def dispatch
        case @record.event_type
        when "checkout.session.completed" then on_checkout_completed
        when /^customer\.subscription\./ then on_subscription_change
        when "invoice.paid" then on_invoice_paid
        when "invoice.payment_failed" then on_payment_failed
        end
      end

      def on_checkout_completed
        membership = Membership.find_by(id: object.dig("metadata", "membership_id"))
        plan = Plan.find_by(id: object.dig("metadata", "plan_id"))
        return unless membership && plan

        subscription = Subscription.find_or_initialize_by(provider_ref: object["subscription"])
        subscription.assign_attributes(
          community_id: membership.community_id, membership: membership, plan: plan,
          provider: "stripe", status: "active"
        )
        subscription.save!
        membership.update!(status: "active", joined_at: membership.joined_at || Time.current)
      end

      def on_subscription_change
        subscription = Subscription.find_by(provider_ref: object["id"])
        return unless subscription

        subscription.update!(
          status: map_status(object["status"]),
          current_period_end: timestamp(object["current_period_end"]),
          trial_ends_at: timestamp(object["trial_end"]),
          cancel_at_period_end: object["cancel_at_period_end"].present?,
          cancelled_at: timestamp(object["canceled_at"])
        )
        sync_membership(subscription)
      end

      def on_invoice_paid
        subscription = Subscription.find_by(provider_ref: object["subscription"])
        Payment.create!(
          community_id: subscription&.community_id || @record.payload.dig("data", "object", "metadata", "community_id"),
          subscription: subscription,
          amount_cents: object["amount_paid"],
          currency: object["currency"].to_s.upcase,
          status: "paid",
          provider_ref: object["id"],
          invoice_url: object["hosted_invoice_url"],
          paid_at: timestamp(object["status_transitions"]&.dig("paid_at")) || Time.current
        )
        subscription&.update!(status: "active")
        subscription && sync_membership(subscription)
      end

      def on_payment_failed
        subscription = Subscription.find_by(provider_ref: object["subscription"])
        return unless subscription

        # past_due still entitles, for the dunning grace window. Locking someone out the
        # instant a card fails punishes an expired card rather than a non-payer.
        subscription.update!(status: "past_due")
        subscription.membership.update!(status: "past_due")
      end

      def sync_membership(subscription)
        membership = subscription.membership
        membership.update!(status: subscription.entitling? ? "active" : "cancelled")
      end

      def map_status(stripe_status)
        case stripe_status
        when "trialing" then "trialing"
        when "active" then "active"
        when "past_due", "unpaid" then "past_due"
        when "canceled" then "cancelled"
        else "incomplete"
        end
      end

      def timestamp(value) = value.present? ? Time.zone.at(value) : nil
    end
  end
end
