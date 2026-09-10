# frozen_string_literal: true

module Api
  module V1
    class CoursesController < BaseController
      def index
        courses = policy_scope(Course).published.ordered.includes(course_modules: :lessons)
        render json: {
          courses: CourseSerializer.new(courses, params: {
            membership: current_membership, progress: progress_map(courses)
          }).as_json
        }
      end

      def show
        course = policy_scope(Course).find_by!(slug: params[:id])
        authorize course, :show?
        authorize_access!(course)

        lessons = course.lessons.published.includes(:course_module)
        render json: {
          course: CourseSerializer.new(course, params: {
            membership: current_membership, progress: progress_map([course])
          }).as_json,
          modules: course.course_modules.map do |mod|
            { id: mod.id, title: mod.title, position: mod.position,
              lessons: LessonSerializer.new(
                lessons.select { _1.course_module_id == mod.id },
                params: { membership: current_membership, progress: lesson_progress_map(lessons) }
              ).as_json }
          end
        }
      end

      private

      def progress_map(courses)
        courses.index_with { _1.progress_for(current_user) }.transform_keys(&:id)
      end

      def lesson_progress_map(lessons)
        LessonProgress.where(user: current_user, lesson: lessons).index_by(&:lesson_id)
      end
    end
  end
end
