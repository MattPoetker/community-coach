# frozen_string_literal: true

# Posts and comments are tombstoned rather than destroyed: a deleted parent still has to
# anchor its replies, and moderators need to see what was removed.
module SoftDeletable
  extend ActiveSupport::Concern

  included do
    scope :kept, -> { where(deleted_at: nil) }
    scope :discarded, -> { where.not(deleted_at: nil) }
  end

  def discard! = update!(deleted_at: Time.current)
  def discarded? = deleted_at.present?
  def kept? = !discarded?
end
