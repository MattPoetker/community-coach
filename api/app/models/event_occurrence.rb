# frozen_string_literal: true

class EventOccurrence < ApplicationRecord
  acts_as_tenant :community

  belongs_to :event
  has_many :event_rsvps, dependent: :destroy
  has_one :recording, dependent: :destroy

  scope :upcoming, -> { where(cancelled_at: nil).where(starts_at: Time.current..).order(:starts_at) }
  scope :in_range, ->(from, to) { where(starts_at: from..to).order(:starts_at) }

  def cancelled? = cancelled_at.present? || event.cancelled?
  def going_count = event_rsvps.where(state: "going").count

  def rsvp_for(user) = event_rsvps.find_by(user: user)
end
