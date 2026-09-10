# frozen_string_literal: true

class LessonSerializer < ApplicationSerializer
  attributes :id, :title, :slug, :position, :drip_kind

  attribute(:published) { _1.published? }
  attribute(:has_video) { _1.video_asset_id.present? }

  attribute :access do |lesson|
    membership = params[:membership]
    if membership
      result = Access::Resolver.call(membership, lesson)
      { granted: result.granted?, reason: result.reason,
        message: result.granted? ? nil : Access::Messages.for(result) }
    end
  end

  attribute :progress do |lesson|
    entry = params[:progress]&.dig(lesson.id)
    { state: entry&.state || "unseen", resume_at_seconds: entry&.resume_at_seconds || 0 }
  end
end
