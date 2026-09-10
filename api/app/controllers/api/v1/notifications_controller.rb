# frozen_string_literal: true

module Api
  module V1
    class NotificationsController < BaseController
      skip_after_action :verify_authorized
      skip_after_action :verify_policy_scoped

      def index
        scope = Notification.where(user: current_user).recent.includes(:actor)
        scope = scope.unread if params[:unread] == "true"

        page = paginate(scope)
        render json: { notifications: NotificationSerializer.new(page[:records]).as_json,
                       next_cursor: page[:next_cursor],
                       unread_count: Notification.where(user: current_user, read_at: nil).count }
      end

      def read
        Notification.where(user: current_user, id: params[:id]).update_all(read_at: Time.current)
        head :no_content
      end

      def read_all
        Notification.where(user: current_user, read_at: nil).update_all(read_at: Time.current)
        head :no_content
      end
    end
  end
end
