# frozen_string_literal: true

class Coupon < ApplicationRecord
  acts_as_tenant :community

  validates :code, presence: true, uniqueness: { scope: :community_id }
  validates :duration, inclusion: { in: %w[once repeating forever] }

  def redeemable?
    return false if expires_at&.past?
    return false if max_redemptions && redemptions_count >= max_redemptions

    true
  end
end
