# frozen_string_literal: true

class LessonProgress < ApplicationRecord
  acts_as_tenant :community

  belongs_to :user
  belongs_to :lesson

  validates :state, inclusion: { in: %w[started completed] }
  validates :user_id, uniqueness: { scope: :lesson_id }

  scope :completed, -> { where(state: "completed") }

  def complete!
    update!(state: "completed", completed_at: Time.current)
  end
end
