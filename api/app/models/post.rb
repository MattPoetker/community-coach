# frozen_string_literal: true

class Post < ApplicationRecord
  include SoftDeletable

  KINDS = %w[discussion poll announcement].freeze

  acts_as_tenant :community

  belongs_to :category
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :reactions, as: :reactable, dependent: :destroy
  has_many :mentions, as: :source, dependent: :destroy
  has_many :thread_subscriptions, as: :subject, dependent: :destroy
  has_one :poll, dependent: :destroy

  validates :title, presence: true, length: { maximum: 200 }
  validates :kind, inclusion: { in: KINDS }

  before_validation :set_last_activity, on: :create
  before_save :extract_body_text

  scope :pinned_first, -> { order(Arel.sql("pinned_at IS NULL"), pinned_at: :desc, last_activity_at: :desc) }
  scope :recent, -> { order(last_activity_at: :desc) }

  def pinned? = pinned_at.present?
  def locked? = locked_at.present?

  def touch_activity! = update_column(:last_activity_at, Time.current)

  private

  def set_last_activity
    self.last_activity_at ||= Time.current
  end

  # Search indexes and notification previews read plain text, so it is derived once on write
  # rather than by walking the document on every read.
  def extract_body_text
    return unless body_changed?

    self.body_text = RichText::Document.new(body).to_plain_text
  end
end
