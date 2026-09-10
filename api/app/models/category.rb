# frozen_string_literal: true

class Category < ApplicationRecord
  acts_as_tenant :community

  has_many :posts, dependent: :destroy

  validates :name, presence: true, length: { maximum: 80 }
  validates :slug, presence: true, uniqueness: { scope: :community_id }
  validates :post_permission, inclusion: { in: %w[all admins] }

  scope :ordered, -> { order(:position, :id) }
end
