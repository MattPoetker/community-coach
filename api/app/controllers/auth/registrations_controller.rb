# frozen_string_literal: true

module Auth
  class RegistrationsController < ApplicationController
    skip_before_action :authenticate!
    skip_before_action :require_community!
    skip_after_action :verify_authorized

    def create
      user = User.new(registration_params)
      user.confirmation_token = SecureRandom.urlsafe_base64(32)

      if user.save
        UserMailer.confirmation(user).deliver_later
        join_via_invitation(user) if params[:invitation_token].present?
        render json: { user: UserSerializer.new(user).as_json }, status: :created
      else
        render_error(:unprocessable_content, "invalid", "Check the form and try again.",
                     detail: user.errors.to_hash)
      end
    end

    def confirm
      user = User.find_by(confirmation_token: params.require(:token))
      return render_error(:not_found, "invalid_token", "That confirmation link is not valid.") unless user

      user.update!(confirmed_at: Time.current, confirmation_token: nil)
      head :no_content
    end

    private

    def registration_params
      params.permit(:email_address, :password, :name, :timezone)
    end

    def join_via_invitation(user)
      invitation = ActsAsTenant.without_tenant { Invitation.find_pending(params[:invitation_token]) }
      return unless invitation && invitation.email_address == user.email_address

      ActsAsTenant.with_tenant(invitation.community) do
        Membership.create!(user: user, community: invitation.community,
                           role: invitation.role, status: "active", joined_at: Time.current)
        invitation.update!(accepted_at: Time.current)
      end
    end
  end
end
