# frozen_string_literal: true

class Plan < ApplicationRecord
  INTERVALS = %w[month year one_time].freeze

  acts_as_tenant :community

  has_many :subscriptions, dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: 80 }
  validates :slug, presence: true, uniqueness: { scope: :community_id }
  validates :interval, inclusion: { in: INTERVALS }
  validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }

  scope :visible, -> { where(visible: true).order(:position, :amount_cents) }

  def free? = amount_cents.zero?
  def price = Money.format(amount_cents, currency)
end
