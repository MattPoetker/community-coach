# frozen_string_literal: true

class Report < ApplicationRecord
  STATES = %w[open actioned dismissed].freeze

  acts_as_tenant :community

  belongs_to :reporter, class_name: "User"
  belongs_to :resolved_by, class_name: "User", optional: true
  belongs_to :subject, polymorphic: true

  validates :reason, presence: true
  validates :state, inclusion: { in: STATES }

  scope :open, -> { where(state: "open") }
end
