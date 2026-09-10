# frozen_string_literal: true

class CourseSerializer < ApplicationSerializer
  attributes :id, :title, :slug, :description, :position

  attribute(:published) { _1.published? }
  attribute(:lesson_count) { _1.lessons.size }

  attribute :progress do |course|
    params[:progress]&.dig(course.id) || { completed: 0, total: 0, percent: 0 }
  end

  attribute :locked do |course|
    params[:membership].present? && !Access::Resolver.granted?(params[:membership], course)
  end
end
