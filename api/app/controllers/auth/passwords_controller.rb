# frozen_string_literal: true

module Auth
  class PasswordsController < ApplicationController
    RESET_WINDOW = 2.hours

    skip_before_action :authenticate!
    skip_before_action :require_community!
    skip_after_action :verify_authorized

    # Always 204, whether or not the address exists — otherwise this endpoint enumerates
    # accounts for anyone who wants a list.
    def create
      user = User.find_by(email_address: params.require(:email_address))
      if user
        user.update!(password_reset_token: SecureRandom.urlsafe_base64(32),
                     password_reset_sent_at: Time.current)
        UserMailer.password_reset(user).deliver_later
      end
      head :no_content
    end

    def update
      user = User.find_by(password_reset_token: params.require(:token))
      unless user && user.password_reset_sent_at > RESET_WINDOW.ago
        return render_error(:not_found, "invalid_token", "That reset link has expired.")
      end

      user.password = params.require(:password)
      user.password_reset_token = nil
      user.confirmed_at ||= Time.current
      user.save!
      # A reset exists to lock someone out; leaving their sessions alive defeats it.
      user.revoke_all_sessions!
      head :no_content
    end
  end
end
