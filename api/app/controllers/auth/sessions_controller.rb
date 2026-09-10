# frozen_string_literal: true

module Auth
  class SessionsController < ApplicationController
    skip_before_action :authenticate!, only: %i[create]
    skip_before_action :require_community!
    skip_after_action :verify_authorized

    def create
      user = User.find_by(email_address: params.require(:email_address))

      # Same response for "no such user" and "wrong password" — a distinct 404 turns the
      # login form into an account-existence oracle.
      unless user&.authenticate(params.require(:password).to_s)
        return render_error(:unauthorized, "invalid_credentials",
                            "That email and password do not match.")
      end

      return render_error(:forbidden, "unconfirmed", "Confirm your email first.") unless user.confirmed?

      if user.totp_enabled? && !valid_totp?(user)
        return render_error(:unauthorized, "totp_required", "Enter your authentication code.")
      end

      session = Session.start!(user: user, user_agent: request.user_agent,
                               ip_address: request.remote_ip)
      set_session_cookie(session)
      render json: { user: UserSerializer.new(user).as_json }, status: :created
    end

    def destroy
      Current.session&.destroy
      cookies.delete(SESSION_COOKIE, **cookie_options.except(:value, :expires))
      head :no_content
    end

    # Every other device, for the "someone else is signed in" case.
    def destroy_all
      Current.user.revoke_all_sessions!(except: Current.session)
      head :no_content
    end

    private

    def valid_totp?(user)
      code = params[:totp_code].to_s
      return false if code.blank?

      ROTP::TOTP.new(user.totp_secret).verify(code, drift_behind: 30).present? ||
        consume_recovery_code(user, code)
    end

    def consume_recovery_code(user, code)
      digest = Digest::SHA256.hexdigest(code)
      return false unless user.totp_recovery_codes.include?(digest)

      user.update!(totp_recovery_codes: user.totp_recovery_codes - [digest])
      true
    end

    def set_session_cookie(session)
      cookies.signed[SESSION_COOKIE] = cookie_options.merge(
        value: session.raw_token, expires: session.expires_at
      )
    end

    # SameSite=Lax plus the Origin check in ApplicationController is the CSRF defence for
    # this cookie-authenticated API; in production the __Host- prefix additionally stops a
    # subdomain an attacker controls from setting it.
    def cookie_options
      { httponly: true, secure: SECURE_COOKIES, same_site: :lax, path: "/" }
    end
  end
end
