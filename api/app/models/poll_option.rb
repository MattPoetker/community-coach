# frozen_string_literal: true

class PollOption < ApplicationRecord
  belongs_to :poll
  has_many :poll_votes, dependent: :destroy

  validates :label, presence: true, length: { maximum: 120 }
end
