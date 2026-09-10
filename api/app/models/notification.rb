# frozen_string_literal: true

class Notification < ApplicationRecord
  # Grouping window: repeated activity on the same subject increments one row rather than
  # creating a new one, so ten likes read as "10 people liked" and not ten inbox entries.
  GROUP_WINDOW = 6.hours

  acts_as_tenant :community

  belongs_to :user
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :subject, polymorphic: true, optional: true

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  def read? = read_at.present?

  def self.deliver!(user:, kind:, actor: nil, subject: nil, data: {})
    return if user == actor # nobody needs telling about their own action

    existing = where(user: user, kind: kind, subject: subject)
               .where(read_at: nil, created_at: GROUP_WINDOW.ago..)
               .first

    if existing
      existing.increment!(:group_count)
      existing.touch
      existing
    else
      create!(user: user, kind: kind, actor: actor, subject: subject, data: data)
    end
  end
end
