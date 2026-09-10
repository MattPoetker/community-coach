# frozen_string_literal: true

class Lesson < ApplicationRecord
  DRIP_KINDS = %w[none days_after_join fixed_date].freeze

  acts_as_tenant :community

  belongs_to :course_module
  belongs_to :video_asset, optional: true
  has_one :course, through: :course_module
  has_many :lesson_progresses, dependent: :destroy

  validates :title, presence: true, length: { maximum: 160 }
  validates :slug, presence: true
  validates :drip_kind, inclusion: { in: DRIP_KINDS }

  scope :published, -> { where.not(published_at: nil) }

  def published? = published_at.present?

  # Whether the drip schedule has released this lesson for a given membership. Entitlement
  # (does their plan include it) is a separate question, answered by Access::Resolver.
  def dripped_for?(membership)
    case drip_kind
    when "none" then true
    when "days_after_join" then membership.days_since_joined >= drip_days.to_i
    when "fixed_date" then drip_at.present? && drip_at.past?
    else true
    end
  end

  def drip_available_at(membership)
    case drip_kind
    when "days_after_join" then membership.joined_at && membership.joined_at + drip_days.to_i.days
    when "fixed_date" then drip_at
    end
  end

  def progress_for(user) = lesson_progresses.find_by(user: user)
end
