# frozen_string_literal: true

class Recording < ApplicationRecord
  acts_as_tenant :community

  belongs_to :event_occurrence
  belongs_to :video_asset

  scope :published, -> { where.not(published_at: nil) }
end
