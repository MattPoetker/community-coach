# frozen_string_literal: true

class Membership < ApplicationRecord
  ROLES = %w[owner admin moderator member].freeze
  STATUSES = %w[pending active past_due suspended cancelled].freeze
  STAFF_ROLES = %w[owner admin moderator].freeze

  acts_as_tenant :community

  belongs_to :user
  has_many :subscriptions, dependent: :destroy

  validates :role, inclusion: { in: ROLES }
  validates :status, inclusion: { in: STATUSES }
  validates :user_id, uniqueness: { scope: :community_id }

  scope :active, -> { where(status: %w[active past_due]) }
  scope :staff, -> { where(role: STAFF_ROLES) }

  def staff? = STAFF_ROLES.include?(role)
  def owner? = role == "owner"
  def admin? = %w[owner admin].include?(role)
  def moderator? = staff?

  # `past_due` still reads: access is withdrawn by the dunning job after the grace window,
  # not the instant an invoice fails. A card that expires on holiday should not lock
  # someone out of a community they have paid for all year.
  def active? = %w[active past_due].include?(status)

  def current_subscription
    subscriptions.where.not(status: "cancelled").order(created_at: :desc).first
  end

  def plan_slug = current_subscription&.plan&.slug
  def days_since_joined = joined_at ? ((Time.current - joined_at) / 1.day).floor : 0
end
