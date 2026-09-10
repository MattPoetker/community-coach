# frozen_string_literal: true

module Billing
  # The billing seam. Stripe is the only implementation in v1; the interface exists so
  # Paddle or Lemon Squeezy can be added without touching a call site.
  #
  # Two modes, both of which self-hosters genuinely need:
  #
  #   direct  — the community owner supplies their own Stripe keys and money goes straight
  #             to them. No platform, no fee, no KYC for whoever runs the server. This is
  #             what almost every self-hoster wants, and it is the default.
  #   connect — Stripe Connect with an application fee, for anyone running this as a
  #             multi-tenant hosted service.
  module Provider
    class NotConfigured < StandardError; end

    module_function

    def for(community)
      case ENV.fetch("BILLING_PROVIDER", "stripe")
      when "stripe" then Billing::Stripe::Adapter.new(community)
      else raise NotConfigured, "Unsupported BILLING_PROVIDER"
      end
    end
  end
end
