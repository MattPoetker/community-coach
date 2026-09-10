# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :communities, through: :memberships
  has_many :posts, dependent: :nullify
  has_many :comments, dependent: :nullify
  has_many :notifications, dependent: :delete_all
  has_many :push_subscriptions, dependent: :delete_all

  normalizes :email_address, with: ->(e) { e.to_s.strip.downcase }

  validates :email_address, presence: true, uniqueness: true,
                            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { maximum: 120 }
  validates :password, length: { minimum: 12 }, allow_nil: true

  def confirmed? = confirmed_at.present?
  def totp_enabled? = totp_enabled_at.present?

  def membership_in(community) = memberships.find_by(community: community)

  def initials
    name.split.first(2).filter_map { _1[0] }.join.upcase
  end

  # Password changes invalidate every other session. Anything less means a stolen session
  # survives the reset that was meant to stop it.
  def revoke_all_sessions!(except: nil)
    sessions.where.not(id: except&.id).destroy_all
  end
end
