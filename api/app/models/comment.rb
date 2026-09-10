# frozen_string_literal: true

class Comment < ApplicationRecord
  include SoftDeletable

  MAX_DEPTH = 5

  acts_as_tenant :community

  belongs_to :post, counter_cache: :comments_count
  belongs_to :user
  belongs_to :parent, class_name: "Comment", optional: true
  has_many :replies, class_name: "Comment", foreign_key: :parent_id, dependent: :destroy
  has_many :reactions, as: :reactable, dependent: :destroy
  has_many :mentions, as: :source, dependent: :destroy

  before_validation :assign_path, on: :create
  before_save :extract_body_text
  after_create_commit :touch_post_activity

  validates :depth, numericality: { less_than_or_equal_to: MAX_DEPTH }

  # Ordered subtree fetch in one indexed query — the reason path is an ltree.
  scope :threaded, -> { order(:path) }

  private

  # Replies past MAX_DEPTH attach to the deepest permitted ancestor rather than being
  # rejected. A member should never lose a written reply to a structural rule they cannot see.
  def assign_path
    if parent.nil?
      self.depth = 0
      self.path = "r#{SecureRandom.hex(6)}"
    else
      anchor = parent.depth >= MAX_DEPTH ? ancestor_at_max_depth(parent) : parent
      self.parent = anchor
      self.depth = anchor.depth + 1
      self.path = "#{anchor.path}.r#{SecureRandom.hex(6)}"
    end
  end

  def ancestor_at_max_depth(node)
    node = node.parent while node.depth >= MAX_DEPTH && node.parent
    node
  end

  def extract_body_text
    return unless body_changed?

    self.body_text = RichText::Document.new(body).to_plain_text
  end

  def touch_post_activity = post.touch_activity!
end
