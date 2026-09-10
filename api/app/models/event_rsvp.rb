# frozen_string_literal: true

class EventRsvp < ApplicationRecord
  STATES = %w[going maybe declined].freeze

  acts_as_tenant :community

  belongs_to :event_occurrence
  belongs_to :user

  validates :state, inclusion: { in: STATES }
  validates :user_id, uniqueness: { scope: :event_occurrence_id }

  scope :going, -> { where(state: "going") }
end
