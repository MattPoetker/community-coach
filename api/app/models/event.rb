# frozen_string_literal: true

class Event < ApplicationRecord
  LOCATION_KINDS = %w[zoom meet jitsi url in_person].freeze
  # How far ahead recurring events are materialised. A rolling horizon keeps the
  # occurrences table bounded while covering every calendar view the UI offers.
  MATERIALISE_HORIZON = 12.months

  acts_as_tenant :community

  belongs_to :host, class_name: "User"
  has_many :event_occurrences, -> { order(:starts_at) }, dependent: :destroy
  has_many :recordings, through: :event_occurrences

  validates :title, presence: true, length: { maximum: 160 }
  validates :timezone, presence: true, inclusion: { in: ActiveSupport::TimeZone::MAPPING.values + ["Etc/UTC"] }
  validates :location_kind, inclusion: { in: LOCATION_KINDS }

  after_commit :materialise_occurrences, on: %i[create update]

  scope :live, -> { where(cancelled_at: nil) }

  def recurring? = rrule.present?
  def cancelled? = cancelled_at.present?

  def materialise_occurrences
    Calendar::MaterialiseOccurrences.call(self)
  end
end
