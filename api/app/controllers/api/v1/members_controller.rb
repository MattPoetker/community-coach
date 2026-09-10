# frozen_string_literal: true

module Api
  module V1
    class MembersController < BaseController
      def index
        scope = policy_scope(Membership).active.includes(:user).order(joined_at: :desc)
        scope = scope.where(role: params[:role]) if params[:role].present?

        page = paginate(scope)
        render json: { members: MembershipSerializer.new(page[:records]).as_json,
                       next_cursor: page[:next_cursor] }
      end

      def update
        membership = policy_scope(Membership).find(params[:id])
        authorize membership

        # Only an owner may create another owner, and nobody may demote the last one.
        if membership_params[:role] == "owner" && !current_membership.owner?
          return render_error(:forbidden, "owner_only", "Only the owner can do that.")
        end

        membership.update!(membership_params)
        AuditLog.record!(action: "membership.update", actor: current_user, subject: membership,
                         changes_made: membership.previous_changes.except("updated_at"))
        render json: { member: MembershipSerializer.new(membership).as_json }
      end

      def suspend
        membership = policy_scope(Membership).find(params[:id])
        authorize membership, :update?

        membership.update!(status: "suspended", suspended_at: Time.current,
                           suspension_reason: params[:reason])
        # A suspension that leaves live sessions running is not a suspension.
        membership.user.revoke_all_sessions!
        AuditLog.record!(action: "membership.suspend", actor: current_user, subject: membership)
        head :no_content
      end

      def me
        skip_policy_scope
        skip_authorization
        render json: {
          user: UserSerializer.new(current_user).as_json,
          membership: MembershipSerializer.new(current_membership).as_json,
          unread_notifications: Notification.where(user: current_user, read_at: nil).count
        }
      end
    end
  end
end
