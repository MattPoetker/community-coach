# frozen_string_literal: true

# Rate limits on the endpoints that are attacked: credential stuffing on login, account
# enumeration on password reset, and spam from newly-created accounts.
class Rack::Attack
  throttle("login/ip", limit: 10, period: 5.minutes) do |req|
    req.ip if req.path == "/auth/login" && req.post?
  end

  throttle("login/email", limit: 6, period: 15.minutes) do |req|
    if req.path == "/auth/login" && req.post?
      req.params["email_address"].to_s.downcase.presence
    end
  end

  throttle("password_reset/ip", limit: 5, period: 15.minutes) do |req|
    req.ip if req.path == "/auth/password/reset" && req.post?
  end

  throttle("register/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/auth/register" && req.post?
  end

  throttle("writes/ip", limit: 60, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/api/") && !req.get?
  end

  self.throttled_responder = lambda do |request|
    retry_after = (request.env["rack.attack.match_data"] || {})[:period]
    [429, { "Content-Type" => "application/json", "Retry-After" => retry_after.to_s },
     [{ error: { code: "rate_limited",
                 message: "Too many attempts. Try again in a moment." } }.to_json]]
  end
end
