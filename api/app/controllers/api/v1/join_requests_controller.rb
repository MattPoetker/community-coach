# frozen_string_literal: true

module Api
  module V1
    class JoinRequestsController < BaseController
      skip_before_action :require_membership!, only: %i[create]
      before_action :require_staff!, only: %i[index review]

      def index
        skip_authorization
        requests = policy_scope(JoinRequest).pending.includes(:user).order(created_at: :asc)
        render json: { join_requests: JoinRequestSerializer.new(requests).as_json }
      end

      def create
        skip_authorization
        skip_policy_scope
        if Membership.exists?(user: current_user, community: Current.community)
          return render_error(:conflict, "already_member", "You are already in this community.")
        end

        request = JoinRequest.find_or_initialize_by(user: current_user, community: Current.community)
        request.answers = params.fetch(:answers, {}).permit!.to_h
        request.state = "pending"
        request.save!

        render json: { join_request: JoinRequestSerializer.new(request).as_json }, status: :created
      end

      def review
        skip_authorization
        join_request = policy_scope(JoinRequest).find(params[:id])
        approved = params.require(:decision) == "approve"

        ActiveRecord::Base.transaction do
          join_request.update!(state: approved ? "approved" : "rejected",
                               reviewed_by: current_user, reviewed_at: Time.current)
          if approved
            Membership.create!(user: join_request.user, community: Current.community,
                               role: "member", status: "active", joined_at: Time.current)
          end
        end

        AuditLog.record!(action: "join_request.#{join_request.state}", actor: current_user,
                         subject: join_request)
        render json: { join_request: JoinRequestSerializer.new(join_request).as_json }
      end
    end
  end
end
