# frozen_string_literal: true

class Subscription < ApplicationRecord
  STATUSES = %w[trialing active past_due cancelled incomplete].freeze
  # How long a failed payment keeps access before the dunning job withdraws it.
  DUNNING_GRACE = 7.days

  acts_as_tenant :community

  belongs_to :membership
  belongs_to :plan
  has_many :payments, dependent: :nullify

  validates :status, inclusion: { in: STATUSES }

  scope :entitling, -> { where(status: %w[trialing active past_due]) }

  def entitling? = %w[trialing active].include?(status) || within_dunning_grace?
  def trialing? = status == "trialing"

  def within_dunning_grace?
    status == "past_due" && current_period_end.present? &&
      current_period_end > DUNNING_GRACE.ago
  end
end
