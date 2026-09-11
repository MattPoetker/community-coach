# frozen_string_literal: true

module Api
  module V1
    module Admin
      class CoursesController < BaseController
        def index
          skip_authorization
          courses = Course.ordered.includes(course_modules: :lessons)
          render json: {
            courses: courses.map do |course|
              CourseSerializer.new(course, params: { membership: current_membership }).to_h
                              .merge(published: course.published?, access_rule: course.access_rule)
            end
          }
        end

        def create
          course = Course.new(course_params.merge(community: Current.community))
          authorize course
          course.slug = course.slug.presence || course.title.to_s.parameterize
          course.save!
          render json: { course: CourseSerializer.new(course, params: serializer_params).as_json },
                 status: :created
        end

        def update
          course = Course.find(params[:id])
          authorize course
          course.update!(course_params)
          render json: { course: CourseSerializer.new(course, params: serializer_params).as_json }
        end

        def destroy
          course = Course.find(params[:id])
          authorize course
          course.destroy!
          AuditLog.record!(action: "course.delete", actor: current_user, subject: course)
          head :no_content
        end

        def publish
          course = Course.find(params[:id])
          authorize course, :update?
          course.update!(published_at: course.published? ? nil : Time.current)
          render json: { course: CourseSerializer.new(course, params: serializer_params).as_json }
        end

        private

        def course_params
          params.require(:course).permit(:title, :slug, :description, :position, access_rule: {})
        end

        def serializer_params = { membership: current_membership }
      end
    end
  end
end
