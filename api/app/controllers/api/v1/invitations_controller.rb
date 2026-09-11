# frozen_string_literal: true

module Api
  module V1
    class InvitationsController < BaseController
      before_action :require_staff!

      def index
        skip_authorization
        invitations = policy_scope(Invitation).pending.includes(:invited_by).order(created_at: :desc)
        render json: { invitations: InvitationSerializer.new(invitations).as_json }
      end

      def create
        skip_authorization
        emails = Array(params.require(:email_addresses)).map { _1.to_s.strip.downcase }.compact_blank.uniq
        role = params.fetch(:role, "member")

        return render_error(:bad_request, "no_recipients", "Add at least one email address.") if emails.empty?
        if emails.size > 100
          return render_error(:bad_request, "too_many", "Invite up to 100 people at a time.")
        end

        invitations = emails.filter_map do |email|
          next if already_here?(email)

          invitation = Invitation.issue!(community: Current.community, email: email,
                                         role: role, invited_by: current_user)
          InvitationMailer.invite(invitation, invitation.raw_token).deliver_later
          invitation
        end

        render json: { invitations: InvitationSerializer.new(invitations).as_json,
                       skipped: emails.size - invitations.size }, status: :created
      end

      def destroy
        skip_authorization
        policy_scope(Invitation).find(params[:id]).destroy!
        head :no_content
      end

      private

      # Re-inviting someone who already joined sends a confusing email and creates a token
      # that does nothing, so those addresses are skipped and counted back to the caller.
      def already_here?(email)
        user = User.find_by(email_address: email)
        user && Membership.exists?(user: user, community: Current.community)
      end
    end
  end
end
