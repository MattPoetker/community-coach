# frozen_string_literal: true

module Api
  module V1
    class CheckoutController < BaseController
      skip_before_action :require_membership!, only: %i[create]
      skip_after_action :verify_authorized

      def create
        plan = Current.community.plans.visible.find(params.require(:plan_id))
        membership = current_membership || create_pending_membership

        session = Billing::Provider.for(Current.community).checkout_session(
          plan: plan,
          membership: membership,
          success_url: url_for_client("/welcome?checkout=success"),
          cancel_url: url_for_client("/join?checkout=cancelled"),
          coupon: find_coupon
        )

        render json: { checkout_url: session.url }
      rescue Billing::Provider::NotConfigured => e
        render_error(:service_unavailable, "billing_not_configured", e.message)
      rescue ::Stripe::StripeError => e
        Rails.logger.error("[billing] #{e.class}: #{e.message}")
        render_error(:bad_gateway, "billing_error", "Payment could not be started. Try again.")
      end

      def portal
        session = Billing::Provider.for(Current.community).billing_portal(
          membership: current_membership, return_url: url_for_client("/settings/billing")
        )
        render json: { portal_url: session.url }
      rescue Billing::Provider::NotConfigured => e
        render_error(:service_unavailable, "billing_not_configured", e.message)
      end

      private

      def create_pending_membership
        Membership.create!(user: current_user, community: Current.community,
                           role: "member", status: "pending")
      end

      def find_coupon
        return nil if params[:coupon_code].blank?

        Current.community.coupons.find_by(code: params[:coupon_code])&.then { _1.redeemable? ? _1 : nil }
      end

      def url_for_client(path) = "#{ENV.fetch('APP_URL', request.base_url)}#{path}"
    end
  end
end
