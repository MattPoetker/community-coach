# frozen_string_literal: true

class CourseModule < ApplicationRecord
  acts_as_tenant :community

  belongs_to :course
  has_many :lessons, -> { order(:position) }, dependent: :destroy

  validates :title, presence: true, length: { maximum: 160 }
end
