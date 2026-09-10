# frozen_string_literal: true

class Community < ApplicationRecord
  PRIVACIES = %w[public private secret].freeze

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :custom_domains, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :courses, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :plans, dependent: :destroy
  has_many :invitations, dependent: :destroy
  has_many :join_requests, dependent: :destroy

  validates :slug, presence: true, uniqueness: true,
                   format: { with: /\A[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\z/,
                             message: "may contain lowercase letters, numbers and hyphens" },
                   length: { minimum: 2, maximum: 63 }
  validates :name, presence: true, length: { maximum: 120 }
  validates :privacy, inclusion: { in: PRIVACIES }

  scope :published, -> { where.not(published_at: nil) }

  def owner = memberships.find_by(role: "owner")&.user
  def free? = plans.none? { _1.amount_cents.positive? }

  # Brand inputs an owner has actually set, merged over the chosen preset's defaults.
  # Branding::TokenCompiler turns the result into custom properties.
  def branding_with_defaults
    preset = branding["preset"].presence || "kiln"
    Branding::Presets.fetch(preset).deep_merge(branding.except("preset"))
  end
end
