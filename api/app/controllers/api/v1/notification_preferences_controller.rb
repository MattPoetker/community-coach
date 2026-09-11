# frozen_string_literal: true

module Api
  module V1
    class NotificationPreferencesController < BaseController
      skip_after_action :verify_authorized
      skip_after_action :verify_policy_scoped

      def index
        preferences = NotificationPreference::KINDS.map do |kind|
          NotificationPreference.for(user: current_user, kind: kind)
        end
        render json: { preferences: preferences.map { serialize(_1) } }
      end

      def update
        preference = NotificationPreference.find_or_initialize_by(
          user: current_user, community: Current.community, kind: params.require(:id)
        )
        preference.assign_attributes(params.permit(:in_app, :email, :push).to_h.compact)
        preference.save!
        render json: { preference: serialize(preference) }
      end

      private

      def serialize(preference)
        { kind: preference.kind, in_app: preference.in_app,
          email: preference.email, push: preference.push }
      end
    end
  end
end
