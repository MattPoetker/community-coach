# frozen_string_literal: true

class Payment < ApplicationRecord
  acts_as_tenant :community

  belongs_to :subscription, optional: true

  scope :paid, -> { where(status: "paid") }
end
