# frozen_string_literal: true

class VideoAsset < ApplicationRecord
  STATUSES = %w[uploading processing ready failed].freeze

  acts_as_tenant :community

  has_many :lessons, dependent: :nullify
  has_many :recordings, dependent: :destroy

  validates :status, inclusion: { in: STATUSES }

  scope :ready, -> { where(status: "ready") }

  def ready? = status == "ready"

  # Playback URLs are minted per request and expire quickly. A paywalled lesson whose
  # video URL is permanent is one shared link away from being free.
  def playback_url(expires_in: 4.hours)
    Video.provider.playback_url(self, expires_in: expires_in)
  end
end
