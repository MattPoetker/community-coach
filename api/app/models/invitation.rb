# frozen_string_literal: true

class Invitation < ApplicationRecord
  acts_as_tenant :community

  belongs_to :invited_by, class_name: "User"

  attr_reader :raw_token

  validates :email_address, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, inclusion: { in: Membership::ROLES }

  normalizes :email_address, with: ->(e) { e.to_s.strip.downcase }

  scope :pending, -> { where(accepted_at: nil).where(expires_at: Time.current..) }

  def self.issue!(community:, email:, role:, invited_by:)
    raw = SecureRandom.urlsafe_base64(32)
    invitation = create!(community: community, email_address: email, role: role,
                         invited_by: invited_by, token_digest: Digest::SHA256.hexdigest(raw),
                         expires_at: 14.days.from_now)
    invitation.instance_variable_set(:@raw_token, raw)
    invitation
  end

  def self.find_pending(raw) = pending.find_by(token_digest: Digest::SHA256.hexdigest(raw.to_s))

  def accepted? = accepted_at.present?
end
