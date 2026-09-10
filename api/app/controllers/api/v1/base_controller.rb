# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
      before_action :require_membership!

      private

      # Entitlement check, distinct from Pundit's role check. Anything gated by an
      # access_rule goes through here so the paywall has exactly one implementation.
      #
      # Raises rather than renders: a rendered error does not halt the action, and the
      # lines after the check are exactly the ones that hand out paid content.
      def authorize_access!(resource)
        result = Access::Resolver.call(current_membership, resource)
        raise Access::Denied, result unless result.granted?
      end
    end
  end
end
