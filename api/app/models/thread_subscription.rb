# frozen_string_literal: true

# Why a member hears about a thread. Drives notification fan-out and gives the unsubscribe
# link something concrete to switch off.
class ThreadSubscription < ApplicationRecord
  REASONS = %w[author participant mention manual].freeze

  acts_as_tenant :community

  belongs_to :user
  belongs_to :subject, polymorphic: true

  validates :reason, inclusion: { in: REASONS }

  scope :audible, -> { where(muted: false) }

  def self.ensure!(subject:, user:, reason:)
    find_or_create_by!(subject: subject, user: user) { _1.reason = reason }
  rescue ActiveRecord::RecordNotUnique
    find_by(subject: subject, user: user)
  end
end
