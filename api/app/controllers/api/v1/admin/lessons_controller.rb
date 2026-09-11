# frozen_string_literal: true

module Api
  module V1
    module Admin
      class LessonsController < BaseController
        def create
          course_module = CourseModule.find(params.require(:course_module_id))
          lesson = course_module.lessons.new(lesson_params.merge(community: Current.community))
          authorize lesson
          lesson.slug = lesson.slug.presence || lesson.title.to_s.parameterize
          lesson.position = next_position(course_module) if lesson.position.zero?
          RichText::Document.new(lesson.body).validate! if lesson.body.present?
          lesson.save!
          render json: { lesson: serialize(lesson) }, status: :created
        end

        def update
          lesson = Lesson.find(params[:id])
          authorize lesson
          RichText::Document.new(lesson_params[:body]).validate! if lesson_params[:body]
          lesson.update!(lesson_params)
          render json: { lesson: serialize(lesson) }
        end

        def destroy
          lesson = Lesson.find(params[:id])
          authorize lesson
          lesson.destroy!
          head :no_content
        end

        # Drag-reorder sends the whole ordering rather than a delta, so a dropped request
        # cannot leave the list half-sorted.
        def reorder
          skip_authorization
          ordering = params.require(:lesson_ids).map(&:to_i)
          ActiveRecord::Base.transaction do
            ordering.each_with_index do |id, index|
              Lesson.where(id: id).update_all(position: index)
            end
          end
          head :no_content
        end

        # Direct upload: the browser PUTs straight to object storage, so a large video
        # never passes through Rails.
        def upload_url
          skip_authorization
          asset = VideoAsset.create!(community: Current.community, status: "uploading",
                                     provider: ENV.fetch("VIDEO_PROVIDER", "local"),
                                     original_filename: params[:filename])
          render json: { video_asset_id: asset.id, upload: Video.provider.direct_upload(asset) }
        end

        def uploaded
          skip_authorization
          asset = VideoAsset.find(params.require(:video_asset_id))
          Video.provider.enqueue_processing(asset)
          render json: { status: asset.reload.status }
        end

        private

        def lesson_params
          params.require(:lesson).permit(:title, :slug, :position, :video_asset_id,
                                         :drip_kind, :drip_days, :drip_at, :published_at,
                                         body: {}, access_rule: {})
        end

        def next_position(course_module) = course_module.lessons.maximum(:position).to_i + 1

        def serialize(lesson)
          LessonSerializer.new(lesson, params: { membership: current_membership }).to_h
                          .merge(body: lesson.body, access_rule: lesson.access_rule)
        end
      end
    end
  end
end
