# frozen_string_literal: true

class JoinRequest < ApplicationRecord
  STATES = %w[pending approved rejected].freeze

  acts_as_tenant :community

  belongs_to :user
  belongs_to :reviewed_by, class_name: "User", optional: true

  validates :state, inclusion: { in: STATES }

  scope :pending, -> { where(state: "pending") }
end
