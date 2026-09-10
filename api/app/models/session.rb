# frozen_string_literal: true

class Session < ApplicationRecord
  LIFETIME = 30.days

  belongs_to :user

  scope :active, -> { where(expires_at: Time.current..) }

  # The raw token is returned once, at creation, and only its digest is stored — a database
  # leak then yields no usable sessions.
  attr_reader :raw_token

  def self.start!(user:, user_agent:, ip_address:)
    raw = SecureRandom.urlsafe_base64(48)
    session = create!(
      user: user,
      token_digest: digest(raw),
      user_agent: user_agent&.truncate(255),
      ip_address: ip_address,
      last_active_at: Time.current,
      expires_at: LIFETIME.from_now
    )
    session.instance_variable_set(:@raw_token, raw)
    session
  end

  def self.authenticate(raw)
    return nil if raw.blank?

    active.find_by(token_digest: digest(raw))
  end

  def self.digest(raw) = Digest::SHA256.hexdigest(raw)

  def touch_activity!
    return if last_active_at > 5.minutes.ago

    update_columns(last_active_at: Time.current)
  end
end
