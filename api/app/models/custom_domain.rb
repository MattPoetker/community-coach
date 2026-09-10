# frozen_string_literal: true

class CustomDomain < ApplicationRecord
  belongs_to :community

  validates :hostname, presence: true, uniqueness: true,
                       format: { with: /\A[a-z0-9.-]+\.[a-z]{2,}\z/i }

  scope :verified, -> { where.not(verified_at: nil) }

  def verified? = verified_at.present?
end
