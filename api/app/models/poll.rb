# frozen_string_literal: true

class Poll < ApplicationRecord
  belongs_to :post
  has_many :poll_options, -> { order(:position) }, dependent: :destroy

  def closed? = closes_at.present? && closes_at.past?
  def total_votes = poll_options.sum(:votes_count)
end
