# frozen_string_literal: true

class ApplicationController < ActionController::API
  include ActionController::Cookies
  include Pundit::Authorization

  # Authorization is verified, not trusted. An action that forgets to authorize raises
  # rather than quietly serving data — the failure mode of opt-in authorization is a leak
  # that nobody notices until a member reads someone else's community.
  # Expressed as conditionals rather than :only/:except so that controllers without an
  # index action do not trip Rails' missing-callback-action check.
  after_action :verify_authorized, unless: -> { action_name == "index" }
  after_action :verify_policy_scoped, if: -> { action_name == "index" }

  before_action :set_current_context
  before_action :authenticate!
  before_action :require_community!
  before_action :verify_request_origin!, if: :mutating_request?

  rescue_from Pundit::NotAuthorizedError, with: :forbidden
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable
  rescue_from ActionController::ParameterMissing, with: :bad_request
  rescue_from RichText::Document::InvalidDocument, with: :bad_request
  rescue_from Access::Denied, with: :access_denied

  private

  # The __Host- prefix requires Secure, path=/ and no Domain. Plain-HTTP development
  # cannot satisfy Secure, and browsers reject a __Host- cookie that lacks it outright —
  # so the hardened name is used only where it actually works.
  SECURE_COOKIES = Rails.env.production? || ENV["FORCE_SSL"] == "true"
  SESSION_COOKIE = SECURE_COOKIES ? "__Host-cc_session" : "cc_session"

  def set_current_context
    Current.request_id = request.request_id
    Current.user_agent = request.user_agent
    Current.ip_address = request.remote_ip
    Current.session = Session.authenticate(cookies.signed[SESSION_COOKIE])
    Current.session&.touch_activity!
  end

  def current_user = Current.user
  def current_membership = Current.membership
  def pundit_user = Current.membership

  def authenticate!
    return if Current.user

    render_error(:unauthorized, "authentication_required", "Sign in to continue.")
  end

  def require_community!
    return if Current.community

    render_error(:not_found, "community_not_found",
                 "No community matches this address.")
  end

  def require_membership!
    return if current_membership&.active?

    render_error(:forbidden, "membership_required",
                 "Join this community to see that.")
  end

  def require_staff!
    return if current_membership&.staff?

    render_error(:forbidden, "staff_only", "You do not have permission to do that.")
  end

  # Cookie-authenticated API, so no Rails form tokens. The defence is instead: SameSite=Lax
  # on the session cookie, a strict Origin check on every mutation, and a custom header a
  # browser will not attach cross-site without a preflight. That trio is simpler to keep
  # correct than token rotation, and has no "forgot the token" failure mode.
  def mutating_request? = !request.get? && !request.head?

  def verify_request_origin!
    origin = request.headers["Origin"]
    return if origin.blank? && request.headers["X-Requested-With"] == "CommunityCoach"
    return if origin.present? && allowed_origins.include?(origin)

    render_error(:forbidden, "bad_origin", "Request origin is not allowed.")
  end

  def allowed_origins
    @allowed_origins ||= Array(ENV.fetch("APP_ORIGINS", "").split(",")).map(&:strip).compact_blank
                                                                      .presence || [request.base_url]
  end

  # Cursor pagination everywhere a list can grow. Offset pagination over a feed ordered by
  # last activity duplicates and skips rows the moment anyone posts mid-scroll.
  def paginate(scope, cursor_column: :id, limit: 25)
    limit = params[:limit].to_i.clamp(1, 100) if params[:limit].present?
    limit ||= 25
    scope = scope.where(cursor_column => ...decode_cursor) if params[:cursor].present?
    records = scope.limit(limit + 1).to_a
    more = records.size > limit
    records = records.first(limit)
    { records: records, next_cursor: more ? encode_cursor(records.last&.public_send(cursor_column)) : nil }
  end

  def encode_cursor(value) = value && Base64.urlsafe_encode64(value.to_s, padding: false)

  def decode_cursor
    Base64.urlsafe_decode64(params[:cursor])
  rescue ArgumentError
    raise ActionController::BadRequest, "Malformed cursor"
  end

  def render_error(status, code, message, detail: nil)
    render json: { error: { code: code, message: message, detail: detail }.compact },
           status: status
  end

  def forbidden(exception = nil)
    render_error(:forbidden, "forbidden", "You do not have permission to do that.",
                 detail: exception.try(:policy)&.class&.name)
  end

  def not_found(_ = nil) = render_error(:not_found, "not_found", "That does not exist.")

  def access_denied(exception)
    render_error(:forbidden, exception.result.reason, exception.message,
                 detail: exception.result.detail)
  end

  def unprocessable(exception)
    render_error(:unprocessable_content, "invalid",
                 "That could not be saved.", detail: exception.record&.errors&.to_hash)
  end

  def bad_request(exception) = render_error(:bad_request, "bad_request", exception.message)
end
