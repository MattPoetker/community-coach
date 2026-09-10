# frozen_string_literal: true

class Reaction < ApplicationRecord
  acts_as_tenant :community

  belongs_to :user
  belongs_to :reactable, polymorphic: true, counter_cache: :reactions_count

  validates :kind, presence: true
  validates :user_id, uniqueness: { scope: %i[reactable_type reactable_id kind] }
end
