# frozen_string_literal: true

class CommentSerializer < ApplicationSerializer
  attributes :id, :depth, :reactions_count, :created_at, :edited_at

  attribute(:body) { _1.discarded? ? nil : _1.body }
  attribute(:deleted) { _1.discarded? }
  attribute(:parent_id) { _1.parent_id }
  # The path is what lets the client rebuild the tree without a second query.
  attribute(:path) { _1.path.to_s }

  one :user, resource: UserSerializer
end
