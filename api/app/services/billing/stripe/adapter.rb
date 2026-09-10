# frozen_string_literal: true

module Billing
  module Stripe
    class Adapter
      def initialize(community)
        @community = community
      end

      # Hosted Checkout rather than custom Elements: one fewer surface handling card data,
      # and SCA, wallets and tax are then Stripe's problem rather than ours.
      def checkout_session(plan:, membership:, success_url:, cancel_url:, coupon: nil)
        params = {
          mode: plan.interval == "one_time" ? "payment" : "subscription",
          line_items: [{ price: plan.provider_price_id, quantity: 1 }],
          success_url: success_url,
          cancel_url: cancel_url,
          client_reference_id: membership.id.to_s,
          metadata: { community_id: @community.id, membership_id: membership.id, plan_id: plan.id }
        }
        params[:subscription_data] = { trial_period_days: plan.trial_days } if trial?(plan)
        params[:discounts] = [{ coupon: coupon.code }] if coupon
        params[:customer_email] = membership.user.email_address

        ::Stripe::Checkout::Session.create(params, request_options)
      end

      def billing_portal(membership:, return_url:)
        customer = customer_id_for(membership)
        raise Provider::NotConfigured, "No billing customer for membership" if customer.blank?

        ::Stripe::BillingPortal::Session.create(
          { customer: customer, return_url: return_url }, request_options
        )
      end

      def cancel_at_period_end(subscription)
        ::Stripe::Subscription.update(
          subscription.provider_ref, { cancel_at_period_end: true }, request_options
        )
      end

      private

      def trial?(plan) = plan.trial_days.to_i.positive?

      # In direct mode the community's own key is used; in connect mode the platform key
      # plus a Stripe-Account header. Everything above is identical either way.
      def request_options
        case @community.billing_mode
        when "direct"
          { api_key: secret_key }
        when "connect"
          { api_key: ENV.fetch("STRIPE_PLATFORM_SECRET_KEY"),
            stripe_account: @community.settings["stripe_account_id"] }
        end
      end

      def secret_key
        @community.settings["stripe_secret_key"].presence ||
          ENV["STRIPE_SECRET_KEY"].presence ||
          raise(Provider::NotConfigured, "This community has no Stripe secret key set.")
      end

      def customer_id_for(membership)
        membership.current_subscription&.then { |s| ::Stripe::Subscription.retrieve(s.provider_ref, request_options).customer }
      end
    end
  end
end
