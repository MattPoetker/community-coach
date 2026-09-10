# frozen_string_literal: true

class PostSerializer < ApplicationSerializer
  attributes :id, :title, :kind, :comments_count, :reactions_count,
             :last_activity_at, :created_at, :edited_at

  attribute(:body) { _1.body }
  attribute(:pinned) { _1.pinned? }
  attribute(:locked) { _1.locked? }
  attribute(:excerpt) { _1.body_text.truncate(280) }

  one :user, resource: UserSerializer
  one :category, resource: CategorySerializer

  attribute :reacted do |post|
    params[:reacted_post_ids]&.include?(post.id) || false
  end
end
