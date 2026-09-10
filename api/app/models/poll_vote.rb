# frozen_string_literal: true

class PollVote < ApplicationRecord
  belongs_to :poll_option, counter_cache: :votes_count
  belongs_to :user

  validates :user_id, uniqueness: { scope: :poll_option_id }
end
