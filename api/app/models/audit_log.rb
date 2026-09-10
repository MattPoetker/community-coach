# frozen_string_literal: true

class AuditLog < ApplicationRecord
  belongs_to :community, optional: true
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :subject, polymorphic: true, optional: true

  validates :action, presence: true

  def self.record!(action:, actor: nil, subject: nil, community: nil, changes_made: {}, ip: nil)
    create!(action: action, actor: actor, subject: subject,
            community: community || Current.community,
            changes_made: changes_made, ip_address: ip)
  end
end
