# frozen_string_literal: true

module Api
  module V1
    module Admin
      # Everything under /admin requires staff. Declared once here rather than repeated in
      # each controller, so a new admin endpoint is protected by default instead of by
      # remembering.
      class BaseController < Api::V1::BaseController
        before_action :require_staff!
        skip_after_action :verify_policy_scoped
      end
    end
  end
end
