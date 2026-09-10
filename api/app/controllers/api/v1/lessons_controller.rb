# frozen_string_literal: true

module Api
  module V1
    class LessonsController < BaseController
      def show
        lesson = Lesson.published.find(params[:id])
        authorize lesson, :show?
        # The gate that matters: entitlement plus drip, before any video URL is minted.
        authorize_access!(lesson)

        render json: {
          lesson: LessonSerializer.new(lesson, params: {
            membership: current_membership,
            progress: { lesson.id => lesson.progress_for(current_user) }
          }).as_json,
          body: lesson.body,
          playback_url: lesson.video_asset&.playback_url
        }
      end

      # Progress is a PUT because a player sends it repeatedly; making it idempotent means a
      # dropped response costs nothing.
      def progress
        lesson = Lesson.published.find(params[:id])
        authorize lesson, :show?
        authorize_access!(lesson)

        entry = LessonProgress.find_or_initialize_by(user: current_user, lesson: lesson)
        entry.community = Current.community
        entry.seconds_watched = [entry.seconds_watched, params[:seconds_watched].to_i].max
        entry.resume_at_seconds = params[:resume_at_seconds].to_i
        entry.state = params[:completed] ? "completed" : entry.state.presence || "started"
        entry.completed_at ||= Time.current if params[:completed]
        entry.save!

        render json: { state: entry.state, resume_at_seconds: entry.resume_at_seconds }
      end
    end
  end
end
