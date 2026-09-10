# frozen_string_literal: true

class Course < ApplicationRecord
  acts_as_tenant :community

  has_many :course_modules, -> { order(:position) }, dependent: :destroy
  has_many :lessons, through: :course_modules

  validates :title, presence: true, length: { maximum: 160 }
  validates :slug, presence: true, uniqueness: { scope: :community_id }

  scope :published, -> { where.not(published_at: nil) }
  scope :ordered, -> { order(:position, :id) }

  def published? = published_at.present?

  def progress_for(user)
    total = lessons.where.not(published_at: nil).count
    return { completed: 0, total: 0, percent: 0 } if total.zero?

    completed = LessonProgress.where(user: user, lesson: lessons, state: "completed").count
    { completed: completed, total: total, percent: ((completed.to_f / total) * 100).round }
  end
end
